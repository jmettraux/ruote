#--
# Copyright (c) 2009, John Mettraux, jmettraux@gmail.com
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
  # Tokyo Cabinet based expstorage.
  #
  # Places all the expressions under expstorage.tch in the work directory.
  #
  class TcExpressionStorage
    include ServiceMixin
    include OwfeServiceLocator
    include ExpressionStorageBase

    attr_reader :db, :path

    def initialize (service_name, application_context)

      service_init(service_name, application_context)

      klass = (defined?(TokyoCabinet) &&
        ( ! application_context[:use_rufus_tokyo])) ?
        Rufus::Edo::Table : Rufus::Tokyo::Table

      linfo { "using #{klass} to access TokyoCabinet" }

      @path =
        application_context[:expstorage_path] ||
        get_work_directory + '/expstorage.tct'

      @db = klass.new(@path)

      set_indexes

      observe_expool
    end

    #
    # Takes care of closing the cabinet
    #
    def stop

      self.close
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

      v = @db[fei.as_string_key]

      return nil unless v

      fexp = Marshal.load(Base64.decode64(v['fexp']))

      fexp.application_context = @application_context
      fexp
    end

    def []= (fei, fexp)

      @db[fei.as_string_key] = {
        'wfid' => fexp.fei.wfid,
        'pwfid' => fexp.fei.parent_workflow_instance_id,
        'class' => fexp.class.name,
        'fexp' => Base64.encode64(Marshal.dump(fexp))
      }
    end

    def delete (fei)

      @db.delete(fei.as_string_key)
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
          q.add('pwfid', :equals, wfid)
        }
      #elsif pwfid = options.delete(:parent_wfid)
      #  @db.query { |q|
      #    q.add('pwfid', :equals, pwfid)
      #  }
      elsif wfidp = options.delete(:wfid_prefix)
        @db.query { |q|
          q.add('wfid', :starts_with, wfidp)
        }
      elsif options.delete(:workitem)
        #
        # union of matching expressions (good perf)
        #
        get_expression_map.workitem_holders.inject([]) do |a, k|
          a += @db.query { |q| q.add('class', :equals, k.to_s) }
        end
      else
        @db.values # everything :(
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

    #
    # Used only by pooltool.ru
    #
    def each

      return unless block_given?

      @db.each do |k, v|
        fexp = Marshal.load(Base64.decode64(v['fexp']))
        yield(fexp.fei, fexp)
      end
    end

    #
    # Closes the underlying database
    #
    def close

      @db.close
      @db = nil
    end

    protected

    #
    # Sets the indexes for the Tokyo Cabinet/Tyrant table.
    #
    def set_indexes

      @db.set_index(:pk, :lexical)
      @db.set_index('wfid', :lexical)
      @db.set_index('pwfid', :lexical)
      @db.set_index('class', :lexical)
    end
  end

end
