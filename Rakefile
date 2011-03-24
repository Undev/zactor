require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "zactor"
  gem.homepage = "http://git.undev.cc/nptv/zactor"
  gem.license = "MIT"
  gem.summary = %Q{Zactor}
  gem.description = %Q{Zactor}
  gem.email = "ceo@prepor.ru"
  gem.authors = ["Andrew Rudenko"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  gem.add_runtime_dependency 'ffi', '> 0.1'
  gem.add_runtime_dependency 'ruby-interface', '> 0'
  gem.add_runtime_dependency 'ffi-rzmq', '> 0.1'
  gem.add_runtime_dependency 'em-zeromq', '> 0.1'
  gem.add_runtime_dependency 'bson', '> 0.1'
  gem.add_runtime_dependency 'bson_ext', '> 0.1'  
  gem.add_runtime_dependency 'activesupport', '> 0.1'
  # gem.add_development_dependency 'rspec', '> 2'
  # gem.add_development_dependency 'rr', '> 0'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
