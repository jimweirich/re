# Optional publish task for Rake

begin
  require 'rake/contrib/sshpublisher'
  require 'rake/contrib/rubyforgepublisher'
  
  publisher = Rake::CompositePublisher.new
  publisher.add Rake::RubyForgePublisher.new('re-lib', 'jimweirich')
  
  namespace "publish" do
    desc "Publish the Documentation to RubyForge."
    task :rdoc => ["rake:rdoc"] do
      publisher.upload
    end
    
    desc "Publish gem re-#{Re::VERSION} to Gem Cutter"
    task :gem => "rake:gem" do
      sh "gem push pkg/re-#{Re::VERSION}.gem"
    end
  end

rescue LoadError => ex
  puts "#{ex.message} (#{ex.class})"
  puts "No Publisher Task Available"
end
