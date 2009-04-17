
require 'rubygems'

require 'fileutils'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'

#require 'rake/rdoctask'
require 'hanna/rdoctask'


gemspec = File.read('ruote.gemspec')
eval "gemspec = #{gemspec}"


CLEAN.include('pkg', 'rdoc', 'work', 'logs')

task :default => [ :clean, :repackage ]

#
# Create a task for generating RDOC
#
Rake::RDocTask.new do |rd|

  rd.main = 'README.txt'
  rd.rdoc_dir = 'rdoc'
  rd.rdoc_files.include('README.txt', 'RELEASE.txt', 'lib/**/*.rb')
  rd.title = 'ruote (OpenWFEru) rdoc'
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
Rake::GemPackageTask.new(gemspec) do |pkg|
  #pkg.need_tar = true
end


#
# changing the version

task :change_version do

  version = ARGV.pop
  `sedip "s/VERSION = '.*'/VERSION = '#{version}'/" lib/openwfe/version.rb`
  `sedip "s/s.version = '.*'/s.version = '#{version}'/" ruote.gemspec`
  exit 0 # prevent rake from triggering other tasks
end


#
# Packaging the source
#
Rake::PackageTask.new('ruote', gemspec.version) do |pkg|

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

