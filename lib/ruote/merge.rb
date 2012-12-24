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


module Ruote

  #--
  # Gathering methods for merging workitems.
  #++

  # Merge workitem 'source' into workitem 'target'.
  #
  # If type is 'override', the source will prevail and be returned.
  #
  # If type is 'mix', the source fields will be merged into the target fields.
  #
  # If type is 'isolate', the source fields will be placed in a separte field
  # in the target workitem. The name of this field is the child_id of the
  # source workitem (a string from '0' to '99999' and beyond)
  #
  # The 'concat' type merges hashes and concats arrays. The 'union' type
  # behaves much like 'concat', but it makes sure to remove duplicates.
  #
  # Warning: 'union' will remove duplicates that were present _before_ the
  # merge.
  #
  def self.merge_workitem(index, target, source, merge_type)

    if merge_type == 'override'

      return source
    end

    if target == nil

      case merge_type

        when 'stack'

          source['fields'] = { 'stack' => [ source['fields'] ] }

        when 'isolate'

          source['fields'] = { (index || 0).to_s => source['fields'] }

        #when 'mix'
           # do nothing
        #when 'union', 'concat'
           # do nothing
      end

      return source
    end

    # else, regular merge

    case merge_type

      when 'mix'

        target['fields'].merge!(source['fields'])

      when 'stack'

        target['fields']['stack'] << source['fields']

      when 'isolate'

        index ||= target['fields'].keys.select { |k| k.match(/^\d+$/) }.size
        target['fields'][index.to_s] = source['fields']

      when 'union', 'concat', 'deep'

        source['fields'].each do |k, sv|

          tv = target['fields'][k]

          if sv.is_a?(Array) and tv.is_a?(Array)
            tv.concat(sv)
            tv.uniq! if merge_type == 'union'
          elsif sv.is_a?(Hash) and tv.is_a?(Hash)
            merge_type == 'deep' ? deep_merge!(tv, sv) : tv.merge!(sv)
          else
            target['fields'][k] = sv
          end
        end
    end

    target
  end

  # Inspired by the one found in ActiveSupport, though not strictly
  # equivalent.
  #
  def self.deep_merge!(target, source)

    target.merge!(source) do |k, o, n|
      o.is_a?(Hash) && n.is_a?(Hash) ? deep_merge!(o, n) : n
    end
  end
end

