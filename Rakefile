
require 'rubygems'

require 'fileutils'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'

#require 'rake/rdoctask'
require 'hanna/rdoctask'


load 'lib/openwfe/version.rb'
  #
  # where the OPENWFERU_VERSION is stored


CLEAN.include('pkg', 'rdoc', 'work', 'logs')


spec = Gem::Specification.new do |s|

  s.name = 'ruote'
  s.version = OpenWFE::OPENWFERU_VERSION
  s.authors = [ 'John Mettraux', 'Alain Hoang' ]
  s.email = 'john at openwfe dot org'
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

task :default => [ :clean, :repackage ]

#
# Create a task for generating RDOC
#
Rake::RDocTask.new do |rd|

  rd.main = 'README.txt'
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include('README.txt', 'RELEASE.txt', 'lib/**/*.rb')
  rd.title = 'OpenWFEru rdoc'
  rd.options << '-N' # line numbers
  rd.options << '-S' # inline source

  #rd.template = "../rubytools/allison/allison.rb" \
  #  if File.exist?("../rubytools/allison")
    #
    # just keeping it as a reference for rdoc templating
    # Allison is nice but classes names plus namespaces are too long
    # for it :(
end

task :rrdoc => :rdoc do
  FileUtils.cp('doc/rdoc-style.css', 'rdoc/')
end

task :upload_rdoc => :rrdoc do
  sh %{
    rsync -azv -e ssh \
      rdoc \
      jmettraux@rubyforge.org:/var/www/gforge-projects/openwferu/
  }
end

#
# Create the various ruote[-.*] gems
#
Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.need_tar = true
end

#
# Packaging the source
#
Rake::PackageTask.new('ruote', OpenWFE::OPENWFERU_VERSION) do |pkg|

  pkg.need_zip = true
  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    'bin/**/*',
    'doc/**/*',
    'examples/**/*',
    'lib/**/*',
    'test/**/*'
  ].to_a
  pkg.package_files.delete('rc.txt')
  pkg.package_files.delete('MISC.txt')
  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end


#
# TEST TASKS

task :clean_work_dir do
  FileUtils.rm_rf('work') if File.exist?('work')
  FileUtils.rm_rf('logs') if File.exist?('logs')
  FileUtils.rm_rf('target') if File.exist?('target')
end

#
# Create a task for handling "quick unit tests"
#
# is triggered by "rake qtest"
# whereas "rake test" will trigger all the tests.
#
Rake::TestTask.new(:test => :clean_work_dir) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test.rb']
  t.verbose = true
end

