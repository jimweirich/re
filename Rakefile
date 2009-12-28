#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['*_test.rb']
end

Rake::RDocTask.new do |rd|
  rd.main = "re.rb"
  rd.rdoc_files = FileList["re.rb"]
end
