#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

  # Pretty printing a caller() array
  #
  def Ruote.caller_to_s (start_index, max_lines=nil)
    s = ''
    caller(start_index + 1).each_with_index do |line, index|
      break if max_lines and index >= max_lines
      s << "   #{line}\n"
    end
    s
  end

  # Deep object duplication
  #
  def Ruote.fulldup (object)

    return object.fulldup if object.respond_to?(:fulldup)
      # trusting client objects providing a fulldup() implementation
      # Tomaso Tosolini 2007.12.11

    begin
      return Marshal.load(Marshal.dump(object))
        # as soon as possible try to use that Marshal technique
        # it's quite fast
    rescue TypeError => te
    end

    if object.is_a?(REXML::Element)
      d = REXML::Document.new object.to_s
      return d if object.kind_of?(REXML::Document)
      return d.root
    end
      # avoiding "TypeError: singleton can't be dumped"

    o = object.class.new

    # some kind of collection ?

    if object.is_a?(Array)
      object.each { |i| o << fulldup(i) }
    elsif object.is_a?(Hash)
      object.each { |k, v| o[fulldup(k)] = fulldup(v) }
    end

    # duplicate the attributes of the object

    object.instance_variables.each do |v|
      value = object.instance_variable_get(v)
      value = fulldup(value)
      begin
        o.instance_variable_set(v, value)
      rescue Exception => e
        # ignore, must be readonly
      end
    end

    o
  end
end

