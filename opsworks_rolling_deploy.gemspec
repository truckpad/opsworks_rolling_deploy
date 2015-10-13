# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opsworks_rolling_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = 'opsworks_rolling_deploy'
  spec.version       = OpsworksRollingDeploy::VERSION
  spec.authors       = ['Romeu Henrique Capparelli Fonseca']
  spec.email         = ['romeu.hcf@gmail.com']

  spec.summary       = 'Utilities for opsworks rolling deploy'
  spec.description   = 'Manage a rolling deploy over opsworks stack instances, removing each node from ELB while deploying to it'
  spec.homepage      = 'https://bitbucket.org/truckpad/opsworks_rolling_deploy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   =  spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'clamp'
  spec.add_runtime_dependency 'aws-sdk'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'json'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'byebug'
end
