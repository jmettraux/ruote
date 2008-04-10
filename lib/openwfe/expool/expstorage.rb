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

require 'fileutils'

#require 'rufus/lru'

require 'openwfe/service'
require 'openwfe/flowexpressionid'
require 'openwfe/rudefinitions'


module OpenWFE

    #
    # This module contains the observe_expool method which binds the
    # storage to the expression pool.
    # It also features a to_s method for the expression storages including
    # it.
    #
    module ExpressionStorageBase

        def observe_expool

            get_expression_pool.add_observer(:update) do |channel, fei, fe|
                ldebug { ":update  for #{fei}" }
                self[fei] = fe
            end
            get_expression_pool.add_observer(:remove) do |channel, fei|
                ldebug { ":delete  for #{fei}" }
                self.delete fei
            end
        end

        #
        # a human readable representation of the content of the expression
        # storage.
        #
        # Warning : this will display the content of the real storage,
        # (especially when called against a cache).
        #
        def to_s

            s = "\n\n==== #{self.class} ===="

            find_expressions.each do |fexp|

                s << "\n"
                if fexp.kind_of?(RawExpression)
                    s << "*raw" 
                else
                    s << "  "
                end
                s << fexp.fei.to_s
            end
            s << "\n==== . ====\n"

            s
        end

        #
        # This method is used by the various implementations of 
        # find_expressions()
        #
        def does_match? (options, fexp_or_fei)

            wfid = options[:wfid]
            wfid_prefix = options[:wfid_prefix]
            parent_wfid = options[:parent_wfid]

            wfname = options[:wfname]
            wfrevision = options[:wfrevision]

            ic = options[:include_classes]
            ec = options[:exclude_classes]
            ic = Array(ic) if ic
            ec = Array(ec) if ec

            cs = options[:consider_subprocesses]

            ap = options[:applied]

            fexp, fei = if fexp_or_fei.is_a?(FlowExpressionId)
                [ nil, fexp_or_fei ]
            else
                [ fexp_or_fei, fexp_or_fei.fei ]
            end

            #
            # let's make it verbose...

            if fexp
                return false if (ap == true and not fexp.apply_time)
                return false if (ap == false and fexp.apply_time)
                return false unless class_accepted?(fexp, ic, ec)
            end

            return false \
                if wfname and fei.wfname != wfname
            return false \
                if wfrevision and fei.wfrevision != wfrevision

            return false \
                if cs and fei.sub_instance_id != ""
            return false \
                if wfid and fei.wfid != wfid
            return false \
                if wfid_prefix and not fei.wfid.match("^#{wfid_prefix}")
            return false \
                if parent_wfid and not fei.parent_wfid == parent_wfid

            true
        end

        #
        # Returns true if the given expression is in the list of included
        # classes or false if it's in the list of excluded classes...
        #
        # include_classes has precedence of exclude_classes.
        #
        def class_accepted? (fexp, include_classes, exclude_classes)

            return false if include_classes and (not include_classes.find do |klazz|
                fexp.is_a?(klazz)
            end)
            return false if exclude_classes and exclude_classes.find do |klazz|
                fexp.is_a?(klazz)
            end

            true
        end
    end

    #
    # This cache uses a LruHash (Least Recently Used) to store expressions.
    # If an expression is not cached, the 'real storage' is consulted.
    # The real storage is supposed to be the service named
    # "expressionStorage.1"
    #
    class CacheExpressionStorage
        include ServiceMixin
        include OwfeServiceLocator
        include ExpressionStorageBase

        #
        # under 20 stored expressions, the unit tests for the 
        # CachedFilePersistedEngine do fail because the persistent storage
        # behind the cache hasn't the time to flush its work queue.
        # a min size limit has been set to 77.
        #
        MIN_SIZE = 77

        DEFAULT_SIZE = 5000

        def initialize (service_name, application_context)

            super()

            service_init(service_name, application_context)

            size = @application_context[:expression_cache_size] || DEFAULT_SIZE
            size = MIN_SIZE unless size > MIN_SIZE

            linfo { "new() size is #{size}" }

            @cache = LruHash.new(size)

            @real_storage = nil

            observe_expool
        end

        def [] (fei)

            #ldebug { "[] size is #{@cache.size}" }
            #ldebug { "[] (sz #{@cache.size}) for #{fei.to_debug_s}" }

            fe = @cache[fei.hash]
            return fe if fe

            #ldebug { "[] (reload) for #{fei.to_debug_s}" }

            fe = get_real_storage[fei]

            unless fe
                #ldebug { "[] (reload) miss for #{fei.to_debug_s}" }
                return nil 
            end

            @cache[fei.hash] = fe

            fe
        end

        def []= (fei, fe)

            ldebug { "[]= caching #{fei}" }

            @cache[fei.hash] = fe
        end

        def delete (fei)

            @cache.delete fei.hash
        end

        def length

            @cache.length
        end

        alias :size :length

        def clear

            @cache.clear
        end

        alias :purge :clear

        #
        # This implementations of find_expressions() immediately passes
        # the call to the underlying real storage.
        #
        def find_expressions (options={})

            get_real_storage.find_expressions options
        end

        #
        # Attempts at fetching the root expression of a given process
        # instance.
        #
        def fetch_root (wfid)

            #
            # at first, look in the cache

            @cache.each do |hashed_fei, fexp|

                return fexp \
                    if fexp.fei.wfid == wfid and fexp.is_a?(DefineExpression)
            end

            get_real_storage.fetch_root wfid
        end

        protected

            #
            # Returns the "real storage" i.e. the storage that does the real
            # persistence behind this "cache storage".
            #
            def get_real_storage

                #return @real_storage if @real_storage
                #@real_storage = 
                #    @application_context[S_EXPRESSION_STORAGE + ".1"]
                #@real_storage

                @application_context["expressionStorage.1"]
            end
    end
        
    #
    # Memory consuming in-memory storage.
    # No memory limit, puts everything in a Hash
    #
    class InMemoryExpressionStorage < Hash
        include ServiceMixin
        include OwfeServiceLocator
        include ExpressionStorageBase
        
        def initialize (service_name, application_context)

            service_init service_name, application_context

            observe_expool
        end

        alias :purge :clear

        #--
        # Allows to pass a block to each expressions of a given kind (type).
        #
        #def each_of_kind (kind, &block)
        #    self.each_value do |fexp|
        #        block.call(fexp.fei, fexp) if fexp.kind_of?(kind)
        #    end
        #end
        #
        # An iterator on the expression stored in here.
        #
        #def each (wfid_prefix=nil, &block)
        #    if wfid_prefix
        #        super() do |fei, fexp|
        #            next unless fei.wfid.match "^#{wfid_prefix}"
        #            block.call fei, fexp
        #        end
        #    else
        #        super(&block)
        #    end
        #end
        #alias :real_each :each
        #++

        #
        # Finds expressions matching the given criteria (returns a list
        # of expressions).
        #
        # This methods is called by the expression pool, it's thus not
        # very "public" (not used directly by integrators, who should
        # just focus on the methods provided by the Engine).
        #
        # :wfid ::
        #     will list only one process, 
        #     <tt>:wfid => '20071208-gipijiwozo'</tt>
        # :parent_wfid ::
        #     will list only one process, and its subprocesses,
        #     <tt>:parent_wfid => '20071208-gipijiwozo'</tt>
        # :consider_subprocesses :: 
        #     if true, "process-definition" expressions
        #     of subprocesses will be returned as well.
        # :wfid_prefix :: 
        #     allows your to query for specific workflow instance
        #     id prefixes. for example : 
        #     <tt>:wfid_prefix => "200712"</tt>
        #     for the processes started in December.
        # :include_classes ::
        #     excepts a class or an array of classes, only instances of these
        #     classes will be returned. Parent classes or mixins can be
        #     given.
        #     <tt>:includes_classes => OpenWFE::SequenceExpression</tt>
        # :exclude_classes ::
        #     works as expected.
        # :wfname ::
        #     will return only the expressions who belongs to the given
        #     workflow [name].
        # :wfrevision ::
        #     usued in conjuction with :wfname, returns only the expressions
        #     with a given workflow revision.
        # :applied ::
        #     if this option is set to true, will only return the expressions
        #     that have been applied (exp.apply_time != nil).
        #
        def find_expressions (options={})

            values.find_all do |fexp|
                does_match? options, fexp
            end
        end

        #
        # Attempts at fetching the root expression of a given process
        # instance.
        #
        def fetch_root (wfid)

            find_expressions(
                :wfid => wfid, 
                :include_classes => DefineExpression)[0]
        end

    end

end
