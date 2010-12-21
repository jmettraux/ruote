
$:.unshift('.') # 1.9.2

require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/rdoctask'

require 'lib/ruote/version.rb'


#
# clean

CLEAN.include('pkg', 'rdoc', 'ruote_work', 'ruote_data')

task :default => [ :clean ]


#
# gem

GEMSPEC_FILE = Dir['*.gemspec'].first
GEMSPEC = eval(File.read(GEMSPEC_FILE))
GEMSPEC.validate


desc %{
  builds the gem and places it in pkg/
}
task :build do

  sh "gem build #{GEMSPEC_FILE}"
  sh "mkdir pkg" rescue nil
  sh "mv #{GEMSPEC.name}-#{GEMSPEC.version}.gem pkg/"
end

desc %{
  builds the gem and pushes it to rubygems.org
}
task :push => :build do

  sh "gem push pkg/#{GEMSPEC.name}-#{GEMSPEC.version}.gem"
end


#
# rdoc
#
# make sure to have rdoc 2.5.x to run that

Rake::RDocTask.new do |rd|

  rd.main = 'README.rdoc'
  rd.rdoc_dir = 'rdoc'

  rd.rdoc_files.include(
    'README.rdoc', 'CHANGELOG.txt', 'CREDITS.txt', 'lib/**/*.rb')

  rd.title = "#{GEMSPEC.name} #{GEMSPEC.version}"
end


#
# upload_rdoc

desc %{
  upload the rdoc to rubyforge
}
task :upload_rdoc => [ :clean, :rdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/ruote'

  sh "rsync -azv -e ssh rdoc #{account}:#{webdir}/"
end

