#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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

require 'ostruct'
require 'ruote/util/time'


module Ruote

  #
  # Base methods for storage implementations.
  #
  module StorageBase

    #--
    # misc
    #++

    def context

      @context ||= Ruote::Context.new(self)
    end

    def context=(c)

      @context = c
    end

    # Attempts to delete a document, returns true if the deletion
    # succeeded. This is used with msgs to reserve work on them.
    #
    def reserve(doc)

      delete(doc).nil?
    end

    # Warning, this is not equivalent to doing @context.worker, this method
    # fetches the worker from the local thread variables.
    #
    def worker

      Ruote.current_worker
    end

    #--
    # configurations
    #++

    def get_configuration(key)

      get('configurations', key)
    end

    def replace_engine_configuration(options)

      return if options.delete('preserve_configuration')

      conf = get('configurations', 'engine')

      doc = options.merge('type' => 'configurations', '_id' => 'engine')
      doc['_rev'] = conf['_rev'] if conf

      put(doc)
    end

    #--
    # messages
    #++

    def put_msg(action, options)

      msg = prepare_msg_doc(action, options)

      put(msg)
    end

    def get_msgs

      get_many('msgs', nil, :limit => 300).sort_by { |d| d['put_at'] }
    end

    def empty?(type)

      (get_many(type, nil, :count => true) == 0)
    end

    #--
    # expressions
    #++

    # Given a wfid, returns all the expressions of that process instance.
    #
    def find_expressions(wfid)

      get_many('expressions', wfid)
    end

    # For a given wfid, returns all the expressions (array of Hash instances)
    # that have a nil 'parent_id'.
    #
    def find_root_expressions(wfid)

      find_expressions(wfid).select { |hexp| hexp['parent_id'].nil? }
    end

    # For a given wfid, fetches all the root expressions, sort by expid and
    # return the first. Hopefully it's the right root_expression.
    #
    def find_root_expression(wfid)

      find_root_expressions(wfid).sort_by { |hexp| hexp['fei']['expid'] }.first
    end

    # Given all the expressions stored here, returns a sorted list of unique
    # wfids (this is used in Engine#processes(opts).
    #
    # Understands the :skip, :limit and :descending options.
    #
    # This is a base implementation, different storage implementations may
    # come up with different implementations (think CouchDB,  which could
    # provide a view for it).
    #
    def expression_wfids(opts)

      wfids = ids('expressions').collect { |fei| fei.split('!').last }.uniq.sort

      wfids = wfids.reverse if opts[:descending]

      skip = opts[:skip] || 0
      limit = opts[:limit] || wfids.length

      wfids[skip, limit]
    end

    #--
    # trackers
    #++

    # Some storage implementation might need the wfid information when
    # adding or removing trackers.
    #
    def get_trackers(wfid=nil)

      get('variables', 'trackers') ||
        { '_id' => 'trackers', 'type' => 'variables', 'trackers' => {} }
    end

    #--
    # ats and crons
    #++

    def get_schedules(delta, now)

      # TODO : bring that 'optimization' back in,
      #        maybe every minute, if min != last_min ...

      #if delta < 1.0
      #  at = now.strftime('%Y%m%d%H%M%S')
      #  get_many('schedules', /-#{at}$/)
      #elsif delta < 60.0
      #  at = now.strftime('%Y%m%d%H%M')
      #  scheds = get_many('schedules', /-#{at}\d\d$/)
      #  filter_schedules(scheds, now)
      #else # load all the schedules

      scheds = get_many('schedules')
      filter_schedules(scheds, now)

      #end
    end

    # Places schedule in storage. Returns the id of the 'schedule' document.
    # If the schedule got triggered immediately, nil is returned.
    #
    def put_schedule(flavour, owner_fei, s, msg)

      doc = prepare_schedule_doc(flavour, owner_fei, s, msg)

      return nil unless doc

      r = put(doc)

      raise "put_schedule failed" if r != nil

      doc['_id']
    end

    def delete_schedule(schedule_id)

      return if schedule_id.nil?

      s = get('schedules', schedule_id)
      delete(s) if s
    end

    #--
    # engine variables
    #++

    def get_engine_variable(k)

      get_engine_variables['variables'][k]
    end

    def put_engine_variable(k, v)

      vars = get_engine_variables
      vars['variables'][k] = v

      put_engine_variable(k, v) unless put(vars).nil?
    end

    #--
    # migrations
    #++

    # Copies the content of this storage into a target storage.
    #
    # Of course, the target storage may be a different implementation.
    #
    def copy_to(target, opts={})

      counter = 0

      %w[
        configurations errors expressions msgs schedules variables workitems
      ].each do |type|

        ids(type).each do |id|

          item = get(type, id)

          item.delete('_rev')
          target.put(item)

          counter += 1
          puts("  #{type}/#{item['_id']}") if opts[:verbose]
        end
      end

      counter
    end

    # Used when doing integration tests, removes all
    # msgs, schedules, errors, expressions and workitems.
    #
    # NOTE that it doesn't remove engine variables (danger)
    #
    def clear

      %w[ msgs schedules errors expressions workitems ].each do |type|
        purge_type!(type)
      end
    end

    # Removes a process by removing all its schedules, expressions, errors,
    # workitems and trackers.
    #
    # Warning: will not trigger any cancel behaviours at all, just removes
    # the process.
    #
    def remove_process(wfid)

      2.times do
        # two passes

        Thread.pass

        %w[ schedules expressions errors workitems ].each do |type|
          get_many(type, wfid).each { |d| delete(d) }
        end

        doc = get_trackers

        doc['trackers'].delete_if { |k, v| k.end_with?("!#{wfid}") }

        @context.storage.put(doc)
      end
    end

    def dump(type)

      require 'yaml'

      YAML.dump({ type => get_many(type) })
    end

    protected

    # Used by put_msg
    #
    def prepare_msg_doc(action, options)

      # merge! is way faster than merge (no object creation probably)

      @counter ||= 0

      t = Time.now.utc
      ts = "#{t.strftime('%Y-%m-%d')}!#{t.to_i}.#{'%06d' % t.usec}"
      _id = "#{$$}!#{Thread.current.object_id}!#{ts}!#{'%03d' % @counter}"

      @counter = (@counter + 1) % 1000
        # some platforms (windows) have shallow usecs, so adding that counter...

      msg = options.merge!('type' => 'msgs', '_id' => _id, 'action' => action)

      msg.delete('_rev')
        # in case of message replay

      msg
    end

    # Used by put_schedule
    #
    def prepare_schedule_doc(flavour, owner_fei, s, msg)

      at = if s.is_a?(Time) # at or every
        s
      elsif Ruote.cron_string?(s) # cron
        Rufus::CronLine.new(s).next_time(Time.now + 1)
      else # at or every
        Ruote.s_to_at(s)
      end
      at = at.utc

      if at <= Time.now.utc && flavour == 'at'
        put_msg(msg.delete('action'), msg)
        return false
      end

      sat = at.strftime('%Y%m%d%H%M%S')
      i = "#{flavour}-#{Ruote.to_storage_id(owner_fei)}-#{sat}"

      {
        '_id' => i,
        'type' => 'schedules',
        'flavour' => flavour,
        'original' => s,
        'at' => Ruote.time_to_utc_s(at),
        'owner' => owner_fei,
        'wfid' => owner_fei['wfid'],
        'msg' => msg
      }
    end

    def get_engine_variables

      get('variables', 'variables') || {
        'type' => 'variables', '_id' => 'variables', 'variables' => {} }
    end

    # Returns all the ats whose due date arrived (now or earlier)
    #
    def filter_schedules(schedules, now)

      now = Ruote.time_to_utc_s(now)

      schedules.select { |sch| sch['at'] <= now }
    end

    # Used by #get_many. Returns true whenever one of the keys matches the
    # doc['_id']. Works with strings (_id ends with key) or regexes (_id matches
    # key).
    #
    def key_match?(type, keys, doc)

      _id = doc.is_a?(Hash) ? doc['_id'] : doc

      if keys.first.is_a?(String) && type == 'schedules'
        keys.find { |key| _id.match(/#{key}-\d+$/) }
      elsif keys.first.is_a?(String)
        keys.find { |key| _id.end_with?(key) }
      else # Regexp
        keys.find { |key| _id.match(key) }
      end
    end

    # Used by ruote-couch and ruote-asw
    #
    def self.key_match?(keys, doc)

      _id = doc.is_a?(Hash) ? doc['_id'] : doc

      if keys.first.is_a?(String)
        keys.find { |key| _id.end_with?(key) }
      else # Regexp
        keys.find { |key| _id.match(key) }
      end
    end
  end
end

