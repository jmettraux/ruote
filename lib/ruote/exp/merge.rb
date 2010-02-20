#--
# Copyright (c) 2005-2010, John Mettraux, jmettraux@gmail.com
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


module Ruote::Exp

  #
  # Gathering methods for merging workitems.
  #
  module MergeMixin

    #
    # Merge workitem 'source' into workitem 'target'.
    #
    # If type is 'override', the source will prevail and be returned.
    #
    # If type is 'mix', the source fields will be merge into the target fields.
    #
    # If type is 'isolate', the source fields will be placed in a separte field
    # in the target workitem. The name of this field is the child_id of the
    # source workitem (a string from '0' to '99999' and beyond)
    #
    def merge_workitems (index, target, source, type)

      return source if type == 'override'

      if target == nil
        case type
          when 'isolate'
            source['fields'] = { index.to_s => source['fields'] }
          when 'stack'
            source['fields'] = { 'stack' => [ source['fields'] ] }
        end
      end

      return source unless target

      case type
        when 'mix'
          target['fields'].merge!(source['fields'])
        when 'stack'
          target['fields']['stack'] << source['fields']
          target['fields']['stack_attributes'] = expand_atts
        else # 'isolate'
          target['fields'][index.to_s] = source['fields']
      end

      target
    end
  end
end

