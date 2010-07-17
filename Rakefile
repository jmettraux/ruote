
require 'lib/ruote/version.rb'

require 'rubygems'
require 'rake'

#
# clean

require 'rake/clean'
CLEAN.include('pkg', 'rdoc', 'ruote_work', 'ruote_data', 'logs')

task :default => [ :clean ]


#
# jeweler tasks

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
    gem.authors = [ 'John Mettraux', 'Kenneth Kalmer', 'Torsten Schoenebaum' ]
    gem.rubyforge_project = 'ruote'
    gem.test_file = 'test/test.rb'

    gem.add_dependency 'rufus-json', '>= 0.2.4'
    gem.add_dependency 'rufus-cloche', '>= 0.1.17'
    gem.add_dependency 'rufus-dollar'
    gem.add_dependency 'rufus-mnemo', '>= 1.1.0'
    gem.add_dependency 'rufus-scheduler', '>= 2.0.5'
    gem.add_dependency 'rufus-treechecker', '>= 1.0.3'

    gem.add_development_dependency 'rake'
    gem.add_development_dependency 'yard'
    gem.add_development_dependency 'json'
    gem.add_development_dependency 'builder'
    gem.add_development_dependency 'mailtrap'
    gem.add_development_dependency 'jeweler'

    # Gem::Specification http://www.rubygems.org/read/chapter/20
  end
  Jeweler::GemcutterTasks.new

rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end


#
# rdoc

#begin
#  require 'yard'
#  YARD::Rake::YardocTask.new do |doc|
#    doc.options = [ '-o', 'rdoc', '--title', "ruote #{Ruote::VERSION}" ]
#  end
#rescue LoadError
#  task :yard do
#    abort 'YARD is not available. In order to run yardoc, you must: sudo gem install yard'
#  end
#end

#
# make sure to have rdoc 2.5.x to run that
#
require 'rake/rdoctask'
Rake::RDocTask.new do |rd|

  rd.main = 'README.rdoc'
  rd.rdoc_dir = 'rdoc'

  rd.rdoc_files.include(
    'README.rdoc', 'CHANGELOG.txt', 'CREDITS.txt', 'lib/**/*.rb')

  rd.title = "ruote #{Ruote::VERSION}"
end


#
# upload_rdoc

desc 'Upload the documentation to rubyforge'
task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/ruote'

  sh "rsync -azv -e ssh rdoc #{account}:#{webdir}/"
end

