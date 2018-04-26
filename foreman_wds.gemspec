require File.expand_path('lib/foreman_wds/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'foreman_wds'
  spec.version       = ForemanWds::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['alexander.olofsson@liu.se']

  spec.summary       = 'WDS support for Foreman.'
  spec.description   = 'Adds support for orchestrating WDS deployments with Foreman.'
  spec.homepage      = 'https://github.com/ananace/foreman_wds'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^test\/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'winrm', '~> 2.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
