#!/usr/bin/env ruby

# Copyright 2009 by Jim Weirich (jim.weirich@gmail.com).
# All rights reserved.
#
# Re is provided under the MIT open source license (see MIT-LICENSE)

require 'test/unit'
require 're'

class ReResultTeset < Test::Unit::TestCase
  include Re
  extend Re

  PATTERN = re.any("a-z").one_or_more.capture(:alphas) + re.digits.capture(:digits)

  def setup
    @result = PATTERN.match("<abc123>")
  end

  def test_result_has_full_match
    assert_equal "abc123", @result.full_match
  end

  def test_result_has_individual_matches
    assert_equal "abc", @result[:alphas]
    assert_equal "123", @result[:digits]
  end

  def test_result_has_capture_keys
    assert_equal [:alphas, :digits], @result.keys
  end

  def test_result_has_capture_values
    assert_equal ["abc", "123"], @result.values
  end

  def test_result_can_be_enumerated
    assert_equal [[:alphas, "abc"], [:digits, "123"]], @result.map {
      |item| item
    }
  end
end

class ReTest < Test::Unit::TestCase
  include Re

  def test_module_access_to_re_function
    r = Re.re("a").all
    assert r =~ "a"
  end

  def test_strings_match
    assert re("a") =~ "a"
    assert re("a") !~ "A"
  end

  def test_not_match
    assert re("a") !~ "b"
  end

  def test_special_characters_match
    r = re("()").all
    assert r =~ "()"
  end

  def test_concatenation
    r = re("a") + re("b")
    assert r =~ "ab"
    assert r !~ "xb"
  end

  def test_null
    r = re("a") + re.null + re("b")
    assert r =~ "ab"
  end

  def test_alteration
    r = re("a") | re("b")
    assert r =~ "a"
    assert r =~ "b"
    assert r !~ "x"
  end

  def test_many
    r =  re("x").many.all
    assert r !~ "z"
    assert r =~ ""
    assert r =~ "x"
    assert r =~ "xxx"
  end

  def test_greedy_many
    r =  re.any.many.capture(:x) + re("b")
    result = r.match("xbxb")
    assert result
    assert_equal "xbx", result[:x]
  end

  def test_non_greedy_many
    r =  re.any.non_greedy.many.capture(:x) + re("b")
    result = r.match("xbxb")
    assert result
    assert_equal "x", result[:x]
  end

  def test_one_or_more
    r = re("x").one_or_more.all
    assert r !~ ""
    assert r =~ "x"
    assert r =~ "xxx"
  end

  def test_greedy_one_or_more
    r = re.any.one_or_more.capture(:any) + re("b")
    result = r.match("xbxb")
    assert result
    assert_equal "xbx", result[:any]
  end

  def test_non_greedy_one_or_more
    r = re.any.non_greedy.one_or_more.capture(:any) + re("b")
    result = r.match("xbxb")
    assert result
    assert_equal "x", result[:any]
  end

  def test_repeat_fixed_number
    r = re("a").repeat(3).all
    assert r =~ "aaa"
    assert r !~ "aa"
    assert r !~ "aaaa"
  end

  def test_repeat_range
    r = re("a").repeat(2, 4).all
    assert r !~ "a"
    assert r =~ "aa"
    assert r =~ "aaa"
    assert r =~ "aaaa"
    assert r !~ "aaaaa"
  end

  def test_repeat_greedy
    r = re("a").repeat(2, 4)
    result = r =~ "aaaaa"
    assert_equal "aaaa", result.full_match
  end

  def test_repeat_non_greedy
    r = re("a").non_greedy.repeat(2, 4)
    result = r =~ "aaaaa"
    assert_equal "aa", result.full_match
  end

  def test_at_least
    r = re("a").at_least(2).all
    assert r !~ "a"
    assert r =~ "aa"
    assert r =~ "aaaaaaaaaaaaaaaaaaaa"
  end

  def test_at_least_greedy
    r = re("a").at_least(2)
    result =  r =~ "aaaa"
    assert_equal "aaaa", result.full_match
  end

  def test_at_least_non_greedy
    r = re("a").non_greedy.at_least(2)
    result =  r =~ "aaa"
    assert_equal "aa", result.full_match
  end

  def test_at_most
    r = re("a").at_most(4).all
    assert r =~ ""
    assert r =~ "a"
    assert r =~ "aa"
    assert r =~ "aaa"
    assert r =~ "aaaa"
    assert r !~ "aaaaa"
  end

  def test_at_most_greedy
    r = re("a").at_most(4)
    result = r =~ "aaaa"
    assert_equal "aaaa", result.full_match
  end

  def test_at_most_non_greedy
    r = re("a").non_greedy.at_most(4)
    result = r =~ "aaaa"
    if RUBY_VERSION < "1.9"
      # Ruby 1.8.x seems to have a bug where non-greedy matches with
      # intervals match at least one character.
      assert_equal "a", result.full_match
    else
      assert_equal "", result.full_match
    end
  end

  def test_optional
    r = re("a").optional.all
    assert r =~ ""
    assert r =~ "a"
    assert r !~ "aa"
  end

  def test_any_with_no_arguments
    r = re.any.all
    assert r =~ "a"
    assert r =~ "1"
    assert r =~ "#"
    assert r =~ "."
    assert r =~ " "
    assert r !~ "ab"
    assert r !~ "\n"
  end

  def test_no_options
    r = re("a") + re.any + re("b")
    assert ! r.ignore_case?
    assert ! r.multiline?
    assert r =~ "axb"
    assert r !~ "a\nb"
    assert r !~ "Axb"
  end

  def test_any_with_multiline
    r = re.any.all.multiline
    assert r.multiline?
    assert r =~ "\n"
  end

  def test_ignore_case
    r = re("a").all.ignore_case
    assert r =~ "a"
    assert r =~ "A"
  end

  def test_partial_ignore_case
    r = (re("a").ignore_case + re("b")).all
    assert r =~ "ab"
    assert r =~ "Ab"
    assert r !~ "aB"
  end

  def test_options_no_not_modify_existing_rexps
    r = re("a")
    r2 = r.ignore_case

    assert r !~ "A"
    assert r2 =~ "A"
  end

  def test_any_with_a_character_list
    r = re.any("xyz").all
    assert r !~ "w"
    assert r =~ "x"
    assert r =~ "y"
    assert r =~ "z"
  end

  def test_any_with_special_chars
    r = re.any("^.(-)[]").all
    assert r !~ "x"
    assert r =~ "."
    assert r =~ "^"
    assert r =~ "-"
    assert r =~ "("
    assert r =~ ")"
    assert r =~ "["
    assert r =~ "]"
  end

  def test_any_with_a_range_of_chars
    r = re.any("a-z").many.all
    assert r =~ "abcdefghijklmnopqrstuvwxyz"
  end

  def test_any_with_a_range_and_mix_of_chars
    r = re.any("0-9", ".-").many.all
    assert r =~ "-12.3"
  end

  def test_none_with_a_character_list
    r = re.none("xyz").all
    assert r =~ "w"
    assert r !~ "x"
    assert r !~ "y"
    assert r !~ "z"
  end

  def test_none_with_special_chars
    r = re.none("^.()[]-").all
    assert r =~ "x"
    assert r !~ "."
    assert r !~ "^"
    assert r !~ "-"
    assert r !~ "("
    assert r !~ ")"
    assert r !~ "["
    assert r !~ "]"
  end

  def test_none_with_a_range_of_chars
    r = re.none("a-z").many.all
    assert r =~ "0123()$#"
    assert r !~ "a"
    assert r !~ "b"
    assert r !~ "z"
  end

  def test_none_with_a_range_and_mix_of_chars
    r = re.none("0-9", ".-").many.all
    assert r =~ "abc%^&"
    assert r !~ "-"
    assert r !~ "."
    assert r !~ "1"
  end

  def test_all
    r = re("a").all
    assert r =~ "a"
    assert r !~ "a\n"
    assert r !~ "xa"
    assert r !~ "ax"
  end

  def test_almost_all
    r = re("a").almost_all
    assert r =~ "a"
    assert r =~ "a\n"
    assert r !~ "xa"
    assert r !~ "ax"
  end

  def test_all_across_lines
    r = re("a").many.all
    assert r =~ "a"
    assert r !~ "b\na"
  end

  def test_line
    r = re("a").line
    assert r =~ "a"
    assert r =~ "b\na"
    assert r =~ "b\na\n"
    assert r =~ "b\na\nx"
  end

  def test_bol
    r = re("a").bol
    assert r =~ "a"
    assert r =~ "b\na"
    assert r =~ "b\na"
    assert r !~ "b\nxa"
  end

  def test_eol
    r = re("a").eol
    assert r =~ "a"
    assert r =~ "b\na\nx"
    assert r !~ "b\nax"
    assert r !~ "b\nax\n"
  end

  def test_begin
    r = re("a").begin
    assert r =~ "a"
    assert r =~ "a\nb"
    assert r !~ "b\na"
    assert r !~ "b\na"
    assert r !~ "b\nxa"
  end

  def test_begin2
    r = re.begin + re("a")
    assert r =~ "a"
    assert r =~ "a\nb"
    assert r !~ "b\na"
    assert r !~ "b\na"
    assert r !~ "b\nxa"
  end

  def test_end
    r = re("a").end
    assert r =~ "a"
    assert r =~ "b\na"
    assert r =~ "b\na\n"
    assert r !~ "b\na\nx"
    assert r !~ "b\nax"
    assert r !~ "b\nax\n"
  end

  def test_end2
    r = re("a") + re.end
    assert r =~ "a"
    assert r =~ "b\na"
    assert r =~ "b\na\n"
    assert r !~ "b\na\nx"
    assert r !~ "b\nax"
    assert r !~ "b\nax\n"
  end

  def test_very_end
    r = re("a").very_end
    assert r =~ "a"
    assert r =~ "b\na"
    assert r !~ "b\na\n"
    assert r !~ "b\na\nx"
    assert r !~ "b\nax"
    assert r !~ "b\nax\n"
  end

  def test_hex_digit
    r = re.hex_digit.all
    assert r =~ "1"
    assert r =~ "a"
    assert r =~ "F"
    assert r !~ "12"
    assert r !~ "g"
  end

  def test_hex_digits
    r = re.hex_digits.all
    assert r =~ "1234567890abcedfABCDEF"
    assert r !~ "g"
  end

  def test_digit
    r = re.digit.all
    assert r =~ "0"
    assert r =~ "9"
    assert r !~ "12"
    assert r !~ "x"
    assert r !~ "a"
  end

  def test_digits
    r = re.digits.all
    assert r =~ "0123456789"
    assert r !~ "0123456789x"
  end

  def test_break
    r = re.break + re("a") + re.break
    assert r =~ "there is a home"
    assert r !~ "there is an aardvark"
  end

  def test_nonspace
    r = re.nonspace.all
    assert r =~ "a"
    assert r =~ "1"
    assert r =~ "#"
    assert r !~ "ab"
    assert r !~ " "
    assert r !~ "\t"
    assert r !~ "\n"
  end

  def test_nonspaces
    r = re.nonspaces.all
    assert r =~ "a"
    assert r =~ "asdfhjkl!@\#$%^&*()_+="
    assert r !~ ""
    assert r !~ "a dog"
  end

  def test_space
    r = re.space.all
    assert r =~ " "
    assert r =~ "\t"
    assert r =~ "\n"
    assert r !~ "x"
    assert r !~ ""
    assert r !~ "  "
    assert re.space.many.all =~ " \n\t    "
  end

  def test_spaces
    r = re.spaces.all
    assert r =~ " "
    assert r =~ "  "
    assert r =~ " \t  \n  "
    assert r !~ ""
    assert r !~ "x"
  end

  def test_word_char
    r = re.word_char.all
    assert r =~ "a"
    assert r =~ "1"
    assert r =~ "_"
    assert r !~ "!"
    assert r !~ "?"
  end

  def test_word
    r = re.word.all
    assert r =~ "a"
    assert r =~ "1"
    assert re.word.all =~ "this_is_a_test"
    assert re.word.all !~ "asdf jkl"
  end

  def test_single_capture
    r = re.any("a-z").one_or_more.capture(:word)
    result = (r =~ "012abc789")
    assert result
    assert_equal "abc", result[:word]
  end

  def test_multiple_capture
    word = re.any("a-z").one_or_more.capture(:word)
    number = re.any("0-9").one_or_more.capture(:number)
    r = (word + re.spaces + number).capture(:everything)
    result = (r =~ "   now   123\n")
    assert result
    assert_equal [:everything, :word, :number], r.capture_keys
    assert_equal "now", result[:word]
    assert_equal "123", result[:number]
    assert_equal "now   123", result[:everything]
    assert_equal "now   123", result.full_match
  end

  def test_precedence_concatentaion_vs_alteration
    r = (re("a") | re("b") + re("c")).all
    assert r =~ "a"
    assert r =~ "bc"
    assert r !~ "ac"
  end

  def test_example
    bracketed_delim = re("[") + re.none("]").one_or_more + re("]")
    delims = bracketed_delim.one_or_more.capture(:delims)
    delim_definition = re("//").bol + delims + re("\n")

    result = delim_definition.match("//[a][b][xyz]\n1a2b3xyz4")
    assert result
    assert_equal "[a][b][xyz]", result[:delims]
  end

  def test_date_parser
    assert date_re.match("1900/01/01")
    assert date_re.match("1956/01/01")
    assert date_re.match("2000/01/01")
    assert date_re.match("2010/01/01")
    assert date_re.match("2010/12/01")
    assert date_re.match("2010/03/01")
    assert date_re.match("2010/03/12")
    assert date_re.match("2010/03/24")
    assert date_re.match("2010/03/30")
    assert date_re.match("2010/03/31")

    assert ! date_re.match("2100/01/01")
    assert ! date_re.match("2100/01/32")
    assert ! date_re.match("2010/00/01")
    assert ! date_re.match("2010/13/01")
    assert ! date_re.match("2010/01/00")
    assert ! date_re.match("2010/1/01")
    assert ! date_re.match("2010/01/1")
  end

  def test_date_capture
    result = date_re.match("2010/02/14")
    assert result
    assert_equal "2010", result[:year]
    assert_equal "02", result[:month]
    assert_equal "14", result[:day]
  end

  def test_name_map_returns_map_of_keywords
    r = re("a").capture(:a) + re("b").capture(:b) + re("c").capture(:c)
    result = r.match("abc")
    assert result
    assert_equal 1, r.name_map[:a]
    assert_equal 2, r.name_map[:b]
    assert_equal 3, r.name_map[:c]
  end

  private

  def date_re
    self.class.date_re
  end

  class << self
    include Re
    def date_re
      # /\A((?:19|20)[0-9]{2})[\- \/.](0[1-9]|1[012])[\- \/.](0[1-9]|[12][0-9]|3[01])\z/
      @date_re ||=
        begin
          delim_re                = re.any("- /.")
          century_prefix_re       = re("19") | re("20")
          under_ten_re            = re("0") + re.any("1-9")
          ten_to_twelve_re        = re("1") + re.any("012")
          ten_and_under_thirty_re = re.any("12") + re.any("0-9")
          thirties_re             = re("3") + re.any("01")

          year = century_prefix_re + re.digit.repeat(2)
          month = under_ten_re | ten_to_twelve_re
          day = under_ten_re | ten_and_under_thirty_re | thirties_re

          (year.capture(:year) + delim_re + month.capture(:month) + delim_re + day.capture(:day)).all
        end
    end
  end
end
