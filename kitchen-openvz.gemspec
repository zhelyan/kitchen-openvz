# coding: utf-8
Gem::Specification.new do |spec|
  spec.name = "kitchen-openvz"
  spec.version = "0.2.5"
  spec.authors = ["Zhelyan Panchev", "Jared Russel"]
  spec.email = ["zhelyan.panchev@accenture.com"]
  spec.description = %q{Kitchen driver for OpenVZ containers}
  spec.summary = %q{Kitchen driver for OpenVZ containers}
  spec.homepage = ""
  spec.license = "Apache 2"
  spec.has_rdoc = false

  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("test-kitchen", ">= 1.2.1")

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rake"
end
