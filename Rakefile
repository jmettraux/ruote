
require 'rubygems'

require 'fileutils'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rubygems/package_task'
#require 'rake/testtask'


gemspec = File.read('ruote.gemspec')
eval "gemspec = #{gemspec}"


CLEAN.include('pkg', 'rdoc', 'work', 'logs')

task :default => [ :clean, :repackage ]

task :rdoc do
  sh %{
    rm -fR ruote_rdoc
    yardoc 'lib/**/*.rb' -o ruote_rdoc --title 'ruote 2.0'
  }
end

task :upload_rdoc => :rdoc do
  sh %{
    rsync -azv -e ssh \
      ruote_rdoc \
      jmettraux@rubyforge.org:/var/www/gforge-projects/ruote/
  }
end

task :change_version do

  version = ARGV.pop
  `sedip "s/VERSION = '.*'/VERSION = '#{version}'/" lib/openwfe/version.rb`
  `sedip "s/s.version = '.*'/s.version = '#{version}'/" ruote.gemspec`
  exit 0 # prevent rake from triggering other tasks
end

Gem::PackageTask.new(gemspec) do |pkg|
  #pkg.need_tar = true
end

Rake::PackageTask.new('ruote', gemspec.version) do |pkg|

  pkg.need_zip = true
  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    #'bin/**/*',
    'doc/**/*',
    #'examples/**/*',
    'lib/**/*',
    'test/**/*'
  ].to_a
  #pkg.package_files.delete('rc.txt')
  #pkg.package_files.delete('MISC.txt')
  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end

