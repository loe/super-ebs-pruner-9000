require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "super-ebs-pruner-9000"
    gemspec.summary = "Thins EBS volume snapshots."
    gemspec.description = "Thins EBS volume snapshots."
    gemspec.email = "andrew@andrewloe.com"
    gemspec.homepage = "http://github.com/loe/super-ebs-pruner-9000"
    gemspec.authors = ["W. Andrew Loe III"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

task :default => :test

Rake::TestTask.new(:test) do |test|
  test.test_files = FileList.new('test/**/test_*.rb') do |list|
    list.exclude 'test/test_helper.rb'
  end
  test.libs << 'test'
  test.verbose = true
end