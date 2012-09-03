require 'rubygems'
require './lib/re'

PKG_FILES = FileList[
  '[A-Z]*',
  'rakefile/**/*',
  'lib/*.rb',
  'test/*.rb'
  ]

if ! defined?(Gem)
  puts "Package Target requires RubyGEMs"
else
  require 'rubygems/package_task'
  SPEC = Gem::Specification.new do |s|
    s.name = 're'
    s.version = Re::VERSION
    s.summary = "Construct Ruby Regular Expressions"
    s.description = <<-EOF
     The re library allows the easy construction of regular expressions via an expression language.
    EOF
    s.files = PKG_FILES.to_a
    s.require_path = 'lib'                         # Use these for libraries.
    s.has_rdoc = true
    s.rdoc_options = [
      '--line-numbers', '--inline-source',
      '--main' , 're.rb',
      '--title', 'Re -- Ruby Regular Expression Construction'
    ]
    s.author = "Jim Weirich"
    s.email = "jim.weirich@gmail.com"
    s.homepage = "http://re-lib.rubyforge.org"
    s.rubyforge_project = "re-lib"
  end

  package_task = Gem::PackageTask.new(SPEC) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end
end
