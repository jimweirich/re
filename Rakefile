#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

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

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['test/*_test.rb']
end

Rake::RDocTask.new do |rd|
  rd.main = "lib/re.rb"
  rd.rdoc_files = FileList["lib/re.rb"]
end
