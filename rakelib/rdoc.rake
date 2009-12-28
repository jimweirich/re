file "README.rdoc" => ["lib/re.rb", "Rakefile"] do |t|
  open("lib/re.rb") do |fin|
    open(t.name, "w") do |fout|
      fin.each do |line|
        next if line =~ /^#.*bin\/ruby/
        break if line !~ /^#/
        fout.puts line.sub(/^# ?/,'')
      end
    end
  end
end
