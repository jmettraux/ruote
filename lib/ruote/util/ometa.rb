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

#--
# note, it's ometa, not omerta.
#++

module Ruote

  # meta a la lucky stiff
  #
  module WithMeta

    def self.included(target)

      def target.metaclass
        class << self
          self
        end
      end
      def target.meta_eval(&block)
        metaclass.instance_eval(&block)
      end
      def target.meta_def(method_name, &block)
        meta_eval { define_method method_name, &block }
      end
      def class_def(method_name, &block)
        class_eval { define_method name, &block }
      end
    end
  end

  # A blank slate of a class
  #
  class BlankSlate

    instance_methods.each do |m|

      next if %w[
        method_missing respond_to? instance_eval object_id
      ].include?(m.to_s)

      next if m.to_s.match(/^__/)

      undef_method(m)
    end
  end
end

