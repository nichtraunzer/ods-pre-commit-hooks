# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ods-pre-commit-ruby}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Josef Hartmann / Erhard Wais"]
  s.email = %q{dontneedmoreemail@domain.com}
  s.files = Dir["./hooks/*.rb"]
  s.bindir = 'hooks'
  s.executables   = s.files.grep(%r{^./hooks/}) { |f| File.basename(f) }
  s.require_paths    = ["hooks"]
  s.extra_rdoc_files = ["README.md"]
  s.homepage = %q{https://github.com/nichtraunzer/ods-pre-commit-hooks}
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.license = 'Apache-2.0'
  s.summary = "ruby pre-commit hooks for the ods ecosystem."
  s.description = "A git pre-commit hook written in ruby."

  s.add_development_dependency('benchmark-ips',  '~> 0.1')
  s.add_development_dependency('minitest', '~> 5.0')
  s.add_development_dependency('minitest-reporters', '~> 1.0')
  s.add_development_dependency('rake', '~> 10.0')
  s.add_development_dependency('rubocop', '~> 0.49')

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end
end
