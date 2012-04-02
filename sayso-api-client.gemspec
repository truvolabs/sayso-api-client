# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name = %q{sayso-api-client}
  spec.version = '0.1.3'
  spec.platform = Gem::Platform::RUBY
  spec.description = spec.summary = 'Ruby gem to use the SaySo API (v1).'
  spec.authors = ['Joost Hietbrink']
  spec.email = 'joost@truvolabs.com'
  spec.homepage = %q{http://www.sayso.com}

  spec.add_dependency('oauth')
  spec.add_dependency('crack')
  spec.add_dependency('activesupport')

  spec.files = `git ls-files`.split("\n")
  spec.require_paths = ['lib']
end