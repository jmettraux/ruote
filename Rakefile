
require 'rubygems'
require 'rake'

$:.unshift( File.join(File.dirname(__FILE__), 'lib') )
require File.join(File.dirname(__FILE__), %w[ lib ruote worker.rb ])

begin

  require 'jeweler'

  Jeweler::Tasks.new do |gem|

    gem.version = Ruote::VERSION
    gem.name = 'ruote'
    gem.summary = 'an open source ruby workflow engine'
    gem.description = %{
ruote is an open source ruby workflow engine.
    }
    gem.email = 'jmettraux@gmail.com'
    gem.homepage = 'http://ruote.rubyforge.org'
    gem.authors = [ 'John Mettraux', 'Kenneth Kalmer' ]
    gem.rubyforge_project = 'ruote'
    gem.test_file = 'test/test.rb'

    gem.add_dependency 'rufus-json'
    gem.add_dependency 'rufus-cloche', '>= 0.1.10'
    gem.add_dependency 'rufus-dollar'
    gem.add_dependency 'rufus-lru'
    gem.add_dependency 'rufus-mnemo', '>= 1.1.0'
    gem.add_dependency 'rufus-scheduler', '>= 2.0.3'
    gem.add_dependency 'rufus-treechecker', '>= 1.0.3'

    gem.add_development_dependency 'json'
    gem.add_development_dependency 'yard'

    # Gem::Specification http://www.rubygems.org/read/chapter/20
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |doc|
    doc.options = [ '-o', 'ruote_rdoc', '--title', "ruote #{Ruote::VERSION}" ]
  end
rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yardoc, you must: sudo gem install yard'
  end
end

require 'rake/clean'
CLEAN.include('pkg', 'rdoc', 'work', 'logs')

task :default => [ :clean ]

desc 'Upload the documentation to rubyforge'
task :upload_rdoc => :rdoc do
  sh %{
    rsync -azv -e ssh \
      ruote_rdoc \
      jmettraux@rubyforge.org:/var/www/gforge-projects/ruote/
  }
end

