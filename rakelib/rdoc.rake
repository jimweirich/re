

Rake::RDocTask.new do |rd|
  rd.main = "lib/re.rb"
  rd.rdoc_files = FileList["lib/re.rb", "MIT-LICENSE"]
end
