
Gem::Specification.new do |s|

  s.name = 'ruote'
  s.version = '2.0.0'
  s.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
  s.email = 'jmettraux@gmail.com'
  s.homepage = 'http://ruote.rubyforge.org'
  s.platform = Gem::Platform::RUBY
  s.summary = 'an open source ruby workflow engine'
  s.description = 'an open source ruby workflow engine'

  s.require_path = 'lib'
  s.rubyforge_project = 'ruote'
  #s.autorequire = 'ruote'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = [ 'README.rdoc' ]

  [
    'rufus-scheduler',
    'rufus-dollar',
    'rufus-treechecker',
    'rufus-mnemo',
    'rufus-cloche'
  ].each { |d|
    s.requirements << d
    s.add_dependency(d)
  }

  #files = FileList[ '{bin,docs,lib,test,examples}/**/*' ]
  files = FileList[ '{lib}/**/*' ]
  files.exclude 'ruote_rdoc'
  #files.exclude 'extras'
  s.files = files.to_a
end

