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
  end

rescue LoadError => ex
  puts "#{ex.message} (#{ex.class})"
  puts "No Publisher Task Available"
end
