# -*- encoding: utf-8 -*-
require File.expand_path('../lib/resque-priority-jobs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["rajofchennai"]
  gem.email         = ["rajofchennai@yahoo.com"]
  gem.description   = %q{resque plugin to have priority in the queue}
  gem.summary       = %q{This plugin can be used to have priority inside a queue for resques}
  gem.homepage      = ""

  gem.add_dependency "resque"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "facets"
  gem.add_development_dependency "systemtimer"
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "resque-priority-jobs"
  gem.require_paths = ["lib"]
  gem.version       = Resque::Priority::Jobs::VERSION
end
