require 'lib/re'

task :readme => "README.rdoc"

file "README.rdoc" => ["lib/re.rb", "rakelib/readme.rake"] do |t|
  open("lib/re.rb") do |fin|
    open(t.name, "w") do |fout|
      fin.each do |line|
        next if line =~ /^#.*bin\/ruby/
        break if line !~ /^#/
        if line =~ /Usage:/
          fout.puts "== Version: #{Re::VERSION}"
          fout.puts 
        end
        fout.puts line.sub(/^# ?/,'')
      end
    end
  end
end
