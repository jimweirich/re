

Rake::RDocTask.new do |rd|
  rd.main = "lib/re.rb"
  rd.rdoc_files = FileList["lib/re.rb", "MIT-LICENSE"]
  rd.options = [
    '--title', 'Re - Regular Expressions Library',
    '--main', 'lib/re.rb'
  ]
end
