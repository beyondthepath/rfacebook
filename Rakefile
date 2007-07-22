require "rubygems"
Gem::manage_gems
require "rake/gempackagetask"

spec = Gem::Specification.new do |s| 
  s.name = "rfacebook"
  s.version = "0.6.6"
  s.author = "Matt Pizzimenti"
  s.email = "matt@livelearncode.com"
  s.homepage = "http://livelearncode.com/"
  s.platform = Gem::Platform::RUBY
  s.summary = "A Ruby interface to the Facebook API v1.0+.  Supports the new features from F8."
  s.files = FileList["lib/*"].to_a
  s.require_path = "lib"
  s.autorequire = "rfacebook"
  s.test_files = []#FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
  s.add_dependency("hpricot", ">= 0.6.0")
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end