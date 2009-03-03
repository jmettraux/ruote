#--
# Copyright (c) 2007-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'yaml'
require 'fileutils'

require 'rufus/scheduler'

require 'openwfe/service'
require 'openwfe/rudefinitions'
require 'openwfe/listeners/listener'


#
# some base listener implementations
#
module OpenWFE

  #
  # Polls a directory for incoming workitems (as files).
  #
  # Workitems can be instances of InFlowWorkItem or LaunchItem.
  #
  #   require 'openwfe/listeners/listeners'
  #
  #   engine.add_workitem_listener(
  #     OpenWFE::FileListener,
  #     :frequency => '500',
  #     :folder => '/var/in')
  #
  # In this example, the directory /var/in/ will be polled every 500
  # milliseconds for incoming workitems (or launchitems).
  #
  # The default folder is ./work/in/
  # The listener will make sure to create the folder if not present.
  #
  # You can override the load_object(path) method to manage other formats
  # then YAML.
  #
  class FileListener < Service

    include WorkItemListener
    include Rufus::Schedulable

    attr_reader :workdir

    def initialize (service_name, options)

      super

      @workdir = options[:folder] || 'in/'

      @workdir = "#{get_work_directory}/#{@workdir}" \
        unless @workdir.match(/^\//)

      FileUtils.mkdir_p(@workdir) \
        unless File.exist?(@workdir)

      raise("workdir #{@workdir} is not a directory, cannot setup listener") \
        unless File.directory?(@workdir)

      linfo { "new() workdir is '#{@workdir}'" }
    end

    #
    # Will 'find' files in the work directory (by default ./work/in/),
    # extract the workitem in them and feed it back to the engine.
    #
    def trigger (params)

      #ldebug { "trigger()" }

      FileUtils.mkdir_p(@workdir) unless File.exist?(@workdir)

      Dir["#{@workdir}/*.yaml"].each do |path|

        #ldebug { "trigger() considering file '#{path}'" }

        begin

          object = load_object(path)

          handle_item(object) if object

        rescue Exception => e

          linfo do
            "trigger() failure while loading from '#{path}'. " +
            "Resuming... \n" +
            OpenWFE::exception_to_s(e)
          end
        end
      end
    end

    protected

    #
    # Turns a file into a Ruby instance.
    # This base implementation does it via YAML.
    #
    # (override at will)
    #
    def load_object (path)

      o = YAML.load_file(path)
      File.delete(path)
      o
    end
  end

end

