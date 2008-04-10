#
#--
# Copyright (c) 2006-2008, Nicolas Modryzk and John Mettraux, OpenWFE.org
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.  
# 
# . Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation 
#   and/or other materials provided with the distribution.
# 
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# "made in Japan"
#
# Nicolas Modrzyk at openwfe.org
# John Mettraux at openwfe.org
#

require 'find'
require 'yaml'
require 'monitor'
require 'fileutils'

require 'openwfe/utils'
require 'openwfe/service'

require 'openwfe/expressions/flowexpression'
    #--
    # making sure classes in those files are loaded
    # before their yaml persistence is tuned
    # (else the reopening of the class is interpreted as
    # a definition of the class...)
    #++

module OpenWFE
  
    #
    # Stores OpenWFEru related objects into yaml encoded files.
    # This storage is meant to look and feel like a Hash.
    #
    class YamlFileStorage  
        include MonitorMixin, ServiceMixin
        
        attr_accessor :basepath
        
        def initialize (service_name, application_context, path)

            super()

            service_init(service_name, application_context)

            @basepath = get_work_directory + path
            @basepath += "/" unless @basepath[-1, 1] == "/"

            FileUtils.makedirs @basepath 
        end
        
        #
        # Stores an object with its FlowExpressionId instance as its key.
        #
        def []= (fei, object)
            synchronize do

                #linfo { "[]= #{fei}" }

                fei_path = compute_file_path(fei)

                fei_parent_path = File.dirname(fei_path)
                
                FileUtils.makedirs(fei_parent_path) \
                    unless File.exist?(fei_parent_path)

                File.open(fei_path, "w") do |file|
                    YAML.dump(object, file)
                end
            end
        end
            
        #
        # Deletes the whole storage directory... beware...
        #
        def purge
            synchronize do
                FileUtils.remove_dir @basepath
            end
        end 
        
        #
        # Checks whether there is an object (expression, workitem) stored
        # for the given FlowExpressionId instance.
        #
        def has_key? (fei)
            File.exist?(compute_file_path(fei))
        end
        
        #
        # Removes the object (file) stored for the given FlowExpressionId
        # instance.
        #
        def delete (fei)
            synchronize do
            
                fei_path = compute_file_path(fei)

                ldebug do 
                    "delete()\n   for #{fei.to_debug_s}\n   at #{fei_path}"
                end
                
                File.delete(fei_path)
            end
        end
        
        #
        # Actually loads and returns the object for the given 
        # FlowExpressionId instance.
        #
        def [] (fei)

            fei_path = compute_file_path(fei)
            
            if not File.exist?(fei_path)

                ldebug { "[] didn't find file at #{fei_path}" }
                #puts  "[] didn't find file at #{fei_path}"

                return nil 
            end

            load_object(fei_path)
        end
        
        #
        # Returns the count of objects currently stored in this instance.
        #
        def length

            count_objects()
        end

        alias :size :length
        
        protected 

            def load_object (path)

                object = YAML.load_file(path)
              
                object.application_context = @application_context \
                    if object.respond_to? :application_context=
                
                object
            end
            
            #
            # Returns the number of 'objects' currently in this storage.
            #
            def count_objects

                count = 0

                Find.find(@basepath) do |path|

                    next unless File.exist? path
                    next if File.stat(path).directory?

                    count += 1 if OpenWFE::ends_with(path, ".yaml")
                end

                count
            end

            #
            # Passes each object path to the given block
            #
            def each_object_path (path=@basepath, &block)

                #return unless block

                synchronize do
                    Find.find(path) do |p|

                        next unless File.exist?(p)
                        next if File.stat(p).directory?
                        next unless OpenWFE::ends_with(p, ".yaml")

                        ldebug { "each_object_path() considering #{p}" }
                        block.call p
                    end
                end
            end

            #
            # Passes each object to the given block
            #
            def each_object (&block)

                each_object_path do |path|
                    block.call load_object(path)
                end
            end

            #
            # each_value() is a method from Hash, by providing it here
            # it's easier to disguise a YamlFileStorage as a hash.
            #
            alias :each_value :each_object

            protected
                
                #
                # Each object is meant to have a unique file path,
                # this method wraps the determination of that path. It has to
                # be provided by extending classes.
                #
                def compute_file_path (object)
                    raise NotImplementedError.new
                end
            
        end        
        
    end
