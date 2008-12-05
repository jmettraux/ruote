
require 'rubygems'

require 'fileutils'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

unless RAKEVERSION.match(/^0\.8\./)
  require 'rote'
  require 'rote/filters'
  require 'rote/filters/redcloth'
  require 'rote/filters/tidy'
  require 'rote/format/html'
  require 'rote/extratasks'
  #include Rote
#else
#  puts "rake version #{RAKEVERSION} doesn't play well with 'rote'..."
end


load 'lib/openwfe/version.rb'
  #
  # where the OPENWFERU_VERSION is stored


CLEAN.include("pkg", "html", "rdoc", "work", "logs")

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
  s.test_file = 'test/rake_qtest.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = [ 'README.txt' ]

  [ 'builder',
    #'json_pure',
    'rufus-lru',
    'rufus-scheduler',
    'rufus-dollar',
    'rufus-treechecker',
    'rufus-mnemo',
    'rufus-verbs' ].each do |d|

    s.requirements << d
    s.add_dependency d
  end

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
  #rd.rdoc_dir = 'html/rdoc'
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

unless RAKEVERSION.match(/^0\.8\./)
  #
  # Create a task to build the static docs (html)
  #
  ws = Rote::DocTask.new(:doc) do |site|

    site.output_dir = 'html'
    site.layout_dir = 'doc/layouts'
    site.pages.dir = 'doc/pages'
    site.pages.include('**/*.thtml')

    site.ext_mapping(/thtml|textile/, 'html') do |page|
      page.extend Rote::Format::HTML
      page.page_filter Rote::Filters::RedCloth.new
      page.page_filter Rote::Filters::Syntax.new
    end

    site.res.dir = 'doc/res'
    site.res.include('**/*.png')
    site.res.include('**/*.gif')
    site.res.include('**/*.jpg')
    site.res.include('**/*.css')
    site.res.include('**/*.xml')
    site.res.include('**/*.js')
  end

  #
  # Add rdoc deps to doc task
  #
  task :doc => [ :rdoc ]
end


#
# Builds the website and uploads it to Rubyforge.org
#
task :upload_website => [:doc] do
  upload_website 'openwferu'
  #upload_website 'rufus'
end

def upload_website (target)

  target = "jmettraux@rubyforge.org:/var/www/gforge-projects/#{target}/"

  rso = nil
  #rso = '-n' # blank run

  sh """
rsync -azv #{rso} -e ssh \
html/ \
#{target}
  """
#  sh """
#rsync -azv #{rso} -e ssh \
#rdoc \
##{target}
#  """
  sh """
scp \
doc/res/images/favicon.ico \
#{target}
  """
  sh """
rsync -azv #{rso} -e ssh \
--exclude='.svn' --delete-excluded \
doc/res/defs \
#{target}
  """
  sh """
rsync -azv #{rso} -e ssh \
--exclude='.svn' --delete-excluded \
examples \
#{target}
  """
end


#
# Create the various openwferu[-.*] gems
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

task :setup_p_persistence do
  ENV['__persistence__'] = 'pure-persistence'
end

task :setup_c_persistence do
  ENV['__persistence__'] = 'cached-persistence'
end

task :setup_D_persistence do
  ENV['__persistence__'] = 'db-persistence'
end

task :setup_d_persistence do
  ENV['__persistence__'] = 'cached-db-persistence'
end

#
# Create a task for handling "quick unit tests"
#
# is triggered by "rake qtest"
# whereas "rake test" will trigger all the tests.
#
Rake::TestTask.new(:qtest) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/rake_qtest.rb']
  t.verbose = true
end
task :qtest => :clean_work_dir

#
# The default 'test'
#
task :test => :qtest

#
# pure persistence tests
#
task :ptest => :setup_p_persistence
task :ptest => :qtest

#
# cached persistence tests
#
task :ctest => :setup_c_persistence
task :ctest => :qtest

#
# uncached db persistence tests
#
task :Dtest => :setup_D_persistence
task :Dtest => :qtest

#
# cached db persistence tests
#
task :dtest => :setup_d_persistence
task :dtest => :qtest

#
# The 'long' tests
#
Rake::TestTask.new(:ltest) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/rake_ltest.rb']
  t.verbose = true
end
task :ltest => :clean_work_dir

