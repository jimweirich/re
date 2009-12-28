#!/usr/bin/ruby -wKU
#
# = Regular Expression Construction.
#
# Complex regular expressions are hard to construct and even harder to
# read.  The Re library allows users to construct complex regular
# expressions from simpler expressions.  For example, consider the
# following regular expression that will parse dates:
#
#    /\A((?:19|20)[0-9]{2})[\- \/.](0[1-9]|1[012])[\- \/.](0[1-9]|[12][0-9]|3[01])\z/
#
# That regular expression can be built incrementaly from smaller,
# easier to understand expressions.  Perhaps something like this:
#
#       delim                = re.any("- /.")
#       century_prefix       = re("19") | re("20")
#       under_ten            = re("0") + re.any("1-9")
#       ten_to_twelve        = re("1") + re.any("012")
#       ten_and_under_thirty = re.any("12") + re.any("0-9")
#       thirties             = re("3") + re.any("01")
#          
#       year = (century_prefix + re.digit.repeat(2)).capture(:year)
#       month = (under_ten | ten_to_twelve).capture(:month)
#       day = (under_ten | ten_and_under_thirty | thirties).capture(:day)
#          
#       date = (year + delim + month + delim + day).all
#
# Although it is more code, the individual pieces are smaller and
# easier to independently verify.  As an additional bonus, the capture
# groups can be retrieved by name:
#
#       result = date.match("2009-01-23")
#       result.data(:year)   # => "2009"
#       result.data(:month)  # => "01"
#       result.data(:day)    # => "23"
#
# == Usage:
#
#   include Re
#
#   number = re.any("0-9").all
#   if number =~ string
#     puts "Matches!"
#   else
#     puts "No Match"
#   end
#
# == Examples:
#
#   re("a")                -- matches "a"
#   re("a") + re("b")      -- matches "ab"
#   re("a") | re("b")      -- matches "a" or "b"
#   re("a").many           -- matches "", "a", "aaaaaa"
#   re("a").one_or_more    -- matches "a", "aaaaaa", but not ""
#   re("a").optional       -- matches "" or "a"
#   re("a").all            -- matches "a", but not "xab"
#
# See Re::Rexp for a complete list of expressions.
#
# Using re without an argument allows access to a number of common
# regular expression constants.  For example:
#
#   re.space / re.spaces  -- matches " ", "\n" or "\t"
#   re.digit / re.digits  -- matches a digit / sequence of digits
#
# Also, re without arguments can also be used to construct character
# classes:
#
#   re.any                -- Matches any charactor
#   re.any("abc")         -- Matches "a", "b", or "c"
#   re.any("0-9")         -- Matches the digits 0 through 9
#   re.any("A-Z", "a-z", "0-9", "_")
#                         -- Matches alphanumeric or an underscore
#
# See Re::NULL for a complete list of common constants and character
# class functions.
#
# See Re.re,
# Re::Rexp, and Re::NULL for details.
#
# == Links:
#
# * Documentation :: http://re-lib.rubyforge.org
# * Source        :: http://github.com/jimweirich/re
# * Bug Tracker   :: http://www.pivotaltracker.com/projects/47758
#
module Re
  
  module Version
    NUMBERS = [
      MAJOR = 0,
      MINOR = 0,
      BUILD = 2,
      BETA  = 1,
    ].compact
  end
  VERSION = Version::NUMBERS.join('.')
  
  # Re::Result captures the result of a match and allows lookup of the
  # captured groups by name.
  class Result
    # Create a Re result object with the match data and the origina
    # Re::Rexp object.
    def initialize(match_data, rexp)
      @match_data = match_data
      @rexp = rexp
    end
    
    # Return the full match
    def full_match
      @match_data[0]
    end
    
    # Return the named capture data.
    def [](name)
      index = @rexp.capture_keys.index(name)
      index ? @match_data[index+1] : nil
    end
  end

  # Precedence levels for regular expressions:

  GROUPED = 4                   # (r), [chars]      :nodoc:
  POSTFIX = 3                   # r*, r+, r?        :nodoc:
  CONCAT  = 2                   # r + r, literal    :nodoc:
  ALT     = 1                   # r | r             :nodoc:


  # Constructed regular expressions.
  class Rexp
    attr_reader :string, :level, :options, :capture_keys

    # Create a regular expression from the string.  The regular
    # expression will have a precedence of +level+ and will recognized
    # +keys+ as a list of capture keys.
    def initialize(string, level, options, keys)
      @string = string
      @level = level
      @options = options
      @capture_keys = keys
    end

    # Return a real regular expression from the the constructed
    # regular expression.
    def regexp
      @regexp ||= Regexp.new(string, options)
    end

    # Does it match a string? (returns Re::Result if match, nil otherwise)
    def match(string)
      md = regexp.match(string)
      md ? Result.new(md, self) : nil
    end
    alias =~ match
    
    # Concatenate two regular expressions
    def +(other)
      Rexp.new(parenthesize(CONCAT) + other.parenthesize(CONCAT),
        CONCAT,
        options | other.options,
        capture_keys + other.capture_keys)
    end

    # Matches either self or other
    def |(other)
      Rexp.new(parenthesize(ALT) + "|" + other.parenthesize(ALT),
        ALT,
        options | other.options,
        capture_keys + other.capture_keys)
    end

    # self is optional
    def optional
      Rexp.new(parenthesize(POSTFIX) + "?", POSTFIX, options, capture_keys)
    end

    # self matches many times (zero or more)
    def many
      Rexp.new(parenthesize(POSTFIX) + "*", POSTFIX, options, capture_keys)
    end

    # self matches many times (zero or more) (non-greedy version)
    def many!
      Rexp.new(parenthesize(POSTFIX) + "*?", POSTFIX, options, capture_keys)
    end

    # self matches one or more times
    def one_or_more
      Rexp.new(parenthesize(POSTFIX) + "+", POSTFIX, options, capture_keys)
    end

    # self matches one or more times
    def one_or_more!
      Rexp.new(parenthesize(POSTFIX) + "+?", POSTFIX, options, capture_keys)
    end

    # self is repeated from min to max times.  If max is omitted, then
    # it is repeated exactly min times.
    def repeat(min, max=nil)
      if min && max
        Rexp.new(parenthesize(POSTFIX) + "{#{min},#{max}}", POSTFIX, options, capture_keys)
      else
        Rexp.new(parenthesize(POSTFIX) + "{#{min}}", POSTFIX, options, capture_keys)
      end
    end

    # self is repeated at least min times
    def at_least(min)
      Rexp.new(parenthesize(POSTFIX) + "{#{min},}", POSTFIX, options, capture_keys)
    end

    # self is repeated at least max times
    def at_most(max)
      Rexp.new(parenthesize(POSTFIX) + "{0,#{max}}", POSTFIX, options, capture_keys)
    end

    # None of the given characters will match.
    def none(chars)
      Rexp.new("[^" + Rexp.escape_any(chars) + "]", GROUPED, 0, [])
    end

    # self must match all of the string
    def all
      self.begin.very_end
    end

    # self must match almost all of the string (trailing new lines are allowed)
    def almost_all
      self.begin.end
    end

    # self must match at the beginning of a line
    def bol
      Rexp.new("^" + parenthesize(CONCAT), CONCAT, options, capture_keys)
    end

    # self must match at the end of a line
    def eol
      Rexp.new(parenthesize(CONCAT) + "$", CONCAT, options, capture_keys)
    end

    # self must match at the beginning of the string
    def begin
      Rexp.new("\\A" + parenthesize(CONCAT), CONCAT, options, capture_keys)
    end

    # self must match the end of the string (with an optional new line)
    def end
      Rexp.new(parenthesize(CONCAT) + "\\Z", CONCAT, options, capture_keys)
    end

    # self must match the very end of the string (including any new lines)
    def very_end
      Rexp.new(parenthesize(CONCAT) + "\\z", CONCAT, options, capture_keys)
    end

    # self must match an entire line.
    def line
      self.bol.eol
    end

    # self is contained in a non-capturing group
    def group
      Rexp.new("(?:" + string + ")", GROUPED, options, capture_keys)
    end

    # self is a capturing group with the given name.
    def capture(name)
      Rexp.new("(" + string + ")", GROUPED, options, [name] + capture_keys)
    end
    
    # self will work in multiline matches
    def multiline
      Rexp.new(string, GROUPED, options|Regexp::MULTILINE, capture_keys)
    end
    
    # Is this a multiline regular expression?
    def multiline?
      (options & Regexp::MULTILINE) != 0
    end

    # self will work in multiline matches
    def ignore_case
      Rexp.new(string, GROUPED, options|Regexp::IGNORECASE, capture_keys)
    end

    # Does this regular expression ignore case?
    def ignore_case?
      (options & Regexp::IGNORECASE) != 0
    end

    # String representation of the constructed regular expression.
    def to_s
      regexp.to_s
    end
    
    protected

    # String representation with grouping if needed.
    #
    # If the precedence of the current Regexp is less than the new
    # precedence level, return the string wrapped in a non-capturing
    # group.  Otherwise just return the string.
    def parenthesize(new_level)
      if level >= new_level
        string
      else
        group.string
      end
    end
    
    # Create a literal regular expression (concatenation level
    # precedence, no capture keywords).
    def self.literal(chars)
      new(Regexp.escape(chars), CONCAT, 0, [])
    end

    # Create a regular expression from a raw string representing a
    # regular expression.  The raw string should represent a regular
    # expression with the highest level of precedence (you should use
    # parenthesis if it is not).
    def self.raw(re_string)     # :no-doc:
      new(re_string, GROUPED, 0, [])
    end

    # Escape any special characters.
    def self.escape_any(chars)
      chars.gsub(/([\[\]\^\-])/) { "\\#{$1}" }
    end
  end

  
  # Construct a regular expression from the literal string.  Special
  # Regexp characters will be escaped before constructing the regular
  # expression.  If no literal is given, then the NULL regular
  # expression is returned.
  #
  # See Re for example usage.
  #
  def re(exp=nil)
    exp ? Rexp.literal(exp) : NULL
  end
  extend self
  
  # Matches an empty string.  Additional common regular expression
  # constants are defined as methods on the NULL Rexp.  See Re::NULL.
  NULL = Rexp.literal("")

  # Matches the null string
  def NULL.null
    self
  end

  # :call-seq:
  #   re.any
  #   re.any(chars)
  #   re.any(range)
  #   re.any(chars, range, ...)
  #
  # Match a character from the character class.
  #
  # Any without any arguments will match any single character.  Any
  # with one or more arguments will construct a character class for
  # the arguments.  If the argument is a three character string where
  # the middle character is "-", then the argument represents a range
  # of characters.  Otherwise the arguments are treated as a list of
  # characters to be added to the character class.
  #
  # Examples:
  #
  #   re.any                            -- match any character
  #   re.any("aieouy")                  -- match vowels
  #   re.any("0-9")                     -- match digits
  #   re.any("A-Z", "a-z", "0-9")       -- match alphanumerics
  #   re.any("A-Z", "a-z", "0-9", "_")  -- match alphanumerics
  #
  def NULL.any(*chars)
    if chars.empty?
      @dot ||= Rexp.raw(".")
    else
      any_chars = ''
      chars.each do |chs|
        if /^.-.$/ =~ chs
          any_chars << chs
        else
          any_chars << Rexp.escape_any(chs)
        end
      end
      Rexp.new("[" + any_chars  + "]", GROUPED, 0, [])
    end
  end
  
  # Matches any white space
  def NULL.space
    @space ||= Rexp.raw("\\s")
  end

    # Matches any white space
  def NULL.spaces
    @spaces ||= space.one_or_more
  end

  # Matches any non-white space
  def NULL.nonspace
    @nonspace ||= Rexp.raw("\\S")
  end
  
  # Matches any non-white space
  def NULL.nonspaces
    @nonspaces ||= Rexp.raw("\\S").one_or_more
  end
  
  # Matches any sequence of word characters
  def NULL.word_char
    @word_char ||= Rexp.raw("\\w")
  end
  
  # Matches any sequence of word characters
  def NULL.word
    @word ||= word_char.one_or_more
  end
  
  # Zero-length matches any break
  def NULL.break
    @break ||= Rexp.raw("\\b")
  end
  
  # Matches a digit
  def NULL.digit
    @digit ||= any("0-9")
  end
  
  # Matches a sequence of digits
  def NULL.digits
    @digits ||= digit.one_or_more
  end
  
  # Matches a hex digit (upper or lower case)
  def NULL.hex_digit
    @hex_digit ||= any("0-9", "a-f", "A-F")
  end
  
  # Matches a sequence of hex digits
  def NULL.hex_digits
    @hex_digits ||= hex_digit.one_or_more
  end
end
