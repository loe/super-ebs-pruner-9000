# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{super-ebs-pruner-9000}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["W. Andrew Loe III"]
  s.date = %q{2009-07-24}
  s.default_executable = %q{pruner}
  s.description = %q{Thins EBS volume snapshots.}
  s.email = %q{andrew@andrewloe.com}
  s.executables = ["pruner"]
  s.files = [
    ".gitignore",
     "Rakefile",
     "VERSION",
     "bin/pruner",
     "lib/pruner.rb",
     "lib/pruner/silence_ssl_warning.rb",
     "lib/pruner/version.rb",
     "test/test_pruner.rb"
  ]
  s.homepage = %q{http://github.com/loe/super-ebs-pruner-9000}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Thins EBS volume snapshots.}
  s.test_files = [
    "test/test_pruner.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
