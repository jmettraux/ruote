
Gem::Specification.new do |s|

  s.name = 'ruote'
  s.version = '0.9.21'
  s.authors = [ 'John Mettraux', 'Alain Hoang' ]
  s.email = 'jmettraux@gmail.com'
  s.homepage = 'http://openwferu.rubyforge.org'
  s.platform = Gem::Platform::RUBY
  s.summary = 'an open source ruby workflow and bpm engine'

  s.require_path = 'lib'
  s.rubyforge_project = 'openwferu'
  #s.autorequire = 'ruote'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = [ 'README.txt' ]

  [
    'builder',
    #'json_pure',
    'rufus-lru',
    'rufus-scheduler',
    'rufus-dollar',
    'rufus-treechecker',
    'rufus-mnemo',
    'rufus-verbs'
  ].each { |d|
    s.requirements << d
    s.add_dependency(d)
  }

  files = FileList[ '{bin,docs,lib,test,examples}/**/*' ]
  files.exclude 'rdoc'
  #files.exclude 'extras'
  s.files = files.to_a
end

