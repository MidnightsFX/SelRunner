# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'SelRunner/version'

Gem::Specification.new do |spec|
  spec.name          = "SelRunner"
  spec.version       = SelRunner::VERSION
  spec.authors       = ['Carl Stutz']
  spec.email         = ["carl.stutz@gmail.com"]

  spec.summary       = %q{Gem for running Selenium tests on a selenium grid, queues and manages a set number of parrellel tests..}
  spec.description   = %q{This gem allows the remote calling of a selenium grid to do browser testing. 
    With a provided defined number of browsers, & versions. Test results are currently passed back to the caller.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  end

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency 'simplecov', '~> 0.10.0'
  # spec.add_dependency 'rest-client', '~> 1.8'
  spec.add_dependency 'celluloid', '~> 0.17.3' # Celluloid allows for class based actor multithreading
  spec.add_dependency 'celluloid-io', '~> 0.17.3' # IO compatability
  spec.add_dependency 'selenium-webdriver', '~> 3.0.3' # Selenium Driver for Selenium tests
  spec.add_dependency 'addressable', '~> 2.5', '>= 2.5.2' # Handles URI encoding for API calls
  spec.add_dependency 'slop', '~> 4.3' # Handles CLI
end
