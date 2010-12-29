# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'ruote'
  s.version = File.read('lib/ruote/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux', 'Kenneth Kalmer', 'Torsten Schoenebaum' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://ruote.rubyforge.org'
  s.rubyforge_project = 'ruote'
  s.summary = 'an open source Ruby workflow engine'
  s.description = %{
ruote is an open source Ruby workflow engine
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  #s.add_runtime_dependency 'ruby2ruby', '>= 1.2.5'
  s.add_runtime_dependency 'rufus-json', '>= 0.2.5'
  s.add_runtime_dependency 'rufus-cloche', '>= 0.1.20'
  s.add_runtime_dependency 'rufus-dollar', '>= 1.0.4'
  s.add_runtime_dependency 'rufus-mnemo', '>= 1.1.0'
  s.add_runtime_dependency 'rufus-scheduler', '>= 2.0.5'
  s.add_runtime_dependency 'rufus-treechecker', '>= 1.0.4'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'json'
  s.add_development_dependency 'builder'
  s.add_development_dependency 'mailtrap'

  s.require_path = 'lib'
end

