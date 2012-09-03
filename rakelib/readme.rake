require './lib/re'

class RDocToTextile
  def initialize
    @blanks = 0
  end

  def cleanup(line)
    line.sub(/^# ?/, '').sub(/ +$/, '')
  end

  def emit(line="")
    @outstream.puts line
  end

  def flush_blanks
    @blanks.times do emit("\n") end
    @blanks = 0
  end

  def queue_blank_line
    @blanks += 1
  end

  def output(line="")
    if line =~ /^ *$/
      queue_blank_line
    else
      flush_blanks
      emit(line)
    end
  end

  def translate(line)
    inject_version if line =~ /^== Usage/
    if line =~ /^(=+) (.*)$/
      line = "h#{$1.size}. #{$2}"
    end
    output(line)
  end

  def inject_version
    emit "h2. Version"
    emit
    emit "This document describes Re version #{Re::VERSION}."
    emit
  end

  def copy
    state = :copy
    @instream.each do |line|
      next if line =~ /^#.*bin\/ruby/
      break if line !~ /^#/
      line = cleanup(line)
      case state
      when :copy
        if line == "\n"
          queue_blank_line
        elsif line =~ /^\s/
          flush_blanks
          emit("<pre>")
          output(line)
          state = :pre
        else
          translate(line)
        end
      when :pre
        if line == "\n"
          queue_blank_line
        elsif line =~ /^\S/
          state = :copy
          emit("</pre>")
          translate(line)
        else
          output(line)
        end
      else
        fail "Illegal state"
      end
    end
  end

  def convert(task)
    open("lib/re.rb") do |fin|
      @instream = fin
      open(task.name, "w") do |fout|
        @outstream = fout
        copy
      end
    end
  end
end

task :readme => "README.textile"

file "README.textile" => ["lib/re.rb", "rakelib/readme.rake"] do |t|
  RDocToTextile.new.convert(t)
end
