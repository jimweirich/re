#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['test/*_test.rb']
end
