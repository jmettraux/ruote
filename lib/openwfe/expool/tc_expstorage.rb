#
#--
# Copyright (c) 2009, John Mettraux, OpenWFE.org
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
# John Mettraux at openwfe.org
#

require 'base64'

require 'openwfe/flowexpressionid'
require 'openwfe/expool/expstorage'

require 'rufus/tokyo' # sudo gem install rufus-tokyo

begin
  require 'tokyocabinet' # attempting to load Hirabayashi-san's native bindings
  require 'rufus/edo'
rescue LoadError
end


module OpenWFE

  #
  # re-opening FlowExpression to add a method for determining
  # a 'Tokyo Cabinet key'
  #
  class FlowExpressionId
    def as_tc_key
      "#{@workflow_instance_id} #{@expression_name} #{@expression_id}"
    end
  end

  #
  # Tokyo Cabinet based expstorage.
  #
  # Places all the expressions under expstorage.tch in the work directory.
  #
  class TcExpressionStorage
    include ServiceMixin
    include OwfeServiceLocator
    include ExpressionStorageBase

    def initialize (service_name, application_context)

      service_init(service_name, application_context)

      klass = (defined?(TokyoCabinet) &&
        ( ! application_context[:use_rufus_tokyo])) ?
        Rufus::Edo::Table : Rufus::Tokyo::Table

      @db = klass.new(get_work_directory + '/expstorage.tct')

      #@db.set_index TODO set them !!!

      observe_expool
    end

    #
    # Takes care of closing the cabinet
    #
    def stop

      @db.close
      @db = nil

      super
    end

    #
    # Returns the count of stored expressions
    #
    def size

      @db.size
    end
    alias :length :size

    def [] (fei)

      v = @db[fei.as_tc_key]

      return nil unless v

      fexp = Marshal.load(Base64.decode64(v['fexp']))

      fexp.application_context = @application_context
      fexp
    end

    def []= (fei, fexp)

      @db[fei.as_tc_key] = {
        'wfid' => fexp.fei.wfid,
        'pwfid' => fexp.fei.parent_workflow_instance_id,
        'class' => fexp.class.name,
        'fexp' => Base64.encode64(Marshal.dump(fexp))
      }
    end

    def delete (fei)

      @db.delete(fei.as_tc_key)
    end

    def purge

      @db.clear
    end

    #
    # Finds expressions matching the given criteria (returns a list
    # of expressions).
    #
    # This methods is called by the expression pool, it's thus not
    # very "public" (not used directly by integrators, who should
    # just focus on the methods provided by the Engine).
    #
    # :wfid ::
    #   will list only one process,
    #   <tt>:wfid => '20071208-gipijiwozo'</tt>
    # :parent_wfid ::
    #   will list only one process, and its subprocesses,
    #   <tt>:parent_wfid => '20071208-gipijiwozo'</tt>
    # :consider_subprocesses ::
    #   if true, "process-definition" expressions
    #   of subprocesses will be returned as well.
    # :wfid_prefix ::
    #   allows your to query for specific workflow instance
    #   id prefixes. for example :
    #   <tt>:wfid_prefix => "200712"</tt>
    #   for the processes started in December.
    # :include_classes ::
    #   excepts a class or an array of classes, only instances of these
    #   classes will be returned. Parent classes or mixins can be
    #   given.
    #   <tt>:includes_classes => OpenWFE::SequenceExpression</tt>
    # :exclude_classes ::
    #   works as expected.
    # :wfname ::
    #   will return only the expressions who belongs to the given
    #   workflow [name].
    # :wfrevision ::
    #   usued in conjuction with :wfname, returns only the expressions
    #   with a given workflow revision.
    # :applied ::
    #   if this option is set to true, will only return the expressions
    #   that have been applied (exp.apply_time != nil).
    #
    def find_expressions (options={})

      values = if wfid = options.delete(:wfid)
        @db.query { |q|
          q.add('wfid', :equals, wfid)
        }
      elsif pwfid = options.delete(:parent_wfid)
        @db.query { |q|
          q.add('pwfid', :equals, pwfid)
        }
      elsif wfidp = options.delete(:wfid_prefix)
        @db.query { |q|
          q.add('wfid', :starts_with, wfidp)
        }
      else
        @db.values # everything
      end

      values.inject([]) { |a, v|
        fexp = Marshal.load(Base64.decode64(v['fexp']))
        if does_match?(options, fexp)
          fexp.application_context = @application_context
          a << fexp
        end
        a
      }
    end

    #
    # Attempts at fetching the root expression of a given process
    # instance.
    #
    def fetch_root (wfid)

      find_expressions(
        :wfid => wfid,
        :consider_subprocesses => false,
        :include_classes => DefineExpression)[0]
    end
  end

end
