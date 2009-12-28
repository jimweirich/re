require 'rubygems'

PKG_FILES = FileList[
  'Rakefile',
  'README.rdoc',
  'lib/*.rb',
  'test/*.rb'
  ]

if ! defined?(Gem)
  puts "Package Target requires RubyGEMs"
else
  require 'rake/gempackagetask'
  SPEC = Gem::Specification.new do |s|
    s.name = 're'
    s.version = '0.0.1'
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
    s.homepage = "http://re.rubyforge.org"
    s.rubyforge_project = "re-lib"
  end

  package_task = Rake::GemPackageTask.new(SPEC) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end
end
