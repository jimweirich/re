#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'

require './lib/re'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['test/*_test.rb']
end

namespace "release" do
  task :new => [
    :readme,
    :check_non_beta,
    :check_all_committed,
    :tag_version,
    "publish:rdoc",
    "publish:gem",
  ]

  task :check_all_committed do
    status = `git status`
    unless status =~ /nothing to commit/
      fail "Outstanding Git Changes:\n#{status}"
    end
  end

  task :commit_new_version do
    sh "git commit -m 'bumped to version #{Re::VERSION}'"
  end

  task :not_already_tagged do
    if `git tag -l re-#{Re::VERSION}` != ""
      fail "Already tagged with re-#{Re::VERSION}"
    end
  end

  task :tag_version => :not_already_tagged do
    sh "git tag re-#{Re::VERSION}"
    sh "git push --tags"
  end

  task :check_non_beta do
    fail "Must not be a beta version! Version is #{Re::VERSION}" if Re::Version::BETA
  end
end
task :release => "release:new"
