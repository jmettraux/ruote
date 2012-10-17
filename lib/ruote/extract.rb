#--
# Copyright (c) 2005-2012, John Mettraux, jmettraux@gmail.com
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


#--
#
# Various Ruote.xxx methods.
#
#++
module Ruote

  # A shortcut for
  #
  #   Ruote::FlowExpressionId.to_storage_id(fei)
  #
  def self.to_storage_id(fei)

    Ruote::FlowExpressionId.to_storage_id(fei)
  end

  # A shorter shortcut for
  #
  #   Ruote::FlowExpressionId.to_storage_id(fei)
  #
  def self.sid(fei)

    Ruote::FlowExpressionId.to_storage_id(fei)
  end

  SUBS = %w[ subid sub_wfid ]
  IDS = %w[ engine_id expid wfid ]

  # Returns true if the h is a representation of a FlowExpressionId instance.
  #
  def self.is_a_fei?(o)

    return true if o.is_a?(Ruote::FlowExpressionId)
    return false unless o.is_a?(Hash)

    (o.keys - SUBS).sort == IDS
  end

  # Will do its best to return a wfid (String) or a fei (Hash instance)
  # extract from the given o argument.
  #
  def self.extract_id(o)

    return o if o.is_a?(String) and o.index('!').nil? # wfid

    Ruote::FlowExpressionId.extract_h(o)
  end

  # Given something, tries to return the fei (Ruote::FlowExpressionId) in it.
  #
  def self.extract_fei(o)

    Ruote::FlowExpressionId.extract(o)
  end

  # Given an object, will return the wfid (workflow instance id) nested into
  # it (or nil if it can't find or doesn't know how to find).
  #
  # The wfid is a String instance.
  #
  def self.extract_wfid(o)

    return o.strip == '' ? nil : o if o.is_a?(String)
    return o.wfid if o.respond_to?(:wfid)
    return o['wfid'] || o.fetch('fei', {})['wfid'] if o.respond_to?(:[])
    nil
  end

  # This function is used to generate the subids. Each flow
  # expression receives such an id (it's useful for cursors, loops and
  # forgotten branches).
  #
  def self.generate_subid(salt)

    Digest::MD5.hexdigest(
      "#{rand}-#{salt}-#{$$}-#{Thread.current.object_id}#{Time.now.to_f}")
  end

  # Given a context and a fei (FlowExpressionId or Hash) or a flow expression
  # (Ruote::Exp::FlowExpression or Hash) return the desired
  # Ruote::Exp::FlowExpression instance.
  #
  def self.extract_fexp(context, fei_or_fexp)

    return fei_or_fexp if fei_or_fexp.is_a?(Ruote::Exp::FlowExpression)

    fei = case fei_or_fexp
      when Ruote::FlowExpressionId then fei_or_fexp
      when Hash, String then extract_fei(fei_or_fexp)
      else nil
    end

    raise ArgumentError.new(
      "failed to extract flow expression out of #{fei_or_fexp.class} instance"
    ) unless fei

    Ruote::Exp::FlowExpression.fetch(context, fei)
  end
end

