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


module Ruote
module Exp
  # just introducing the namespace
end
end

require 'ruote/exp/flowexpression'
require 'ruote/exp/raw'


exppath = File.dirname(__FILE__)

Dir.new(exppath).entries.select { |p|
  p.match(/^fe_.*\.rb$/)
}.each { |p|
  require exppath + '/' + p
}


module Ruote

  #
  # Mapping from expression names (sequence, concurrence, ...) to expression
  # classes (Ruote::SequenceExpression, Ruote::ConcurrenceExpression, ...)
  #
  class ExpressionMap

    def initialize (worker)

      @map = {}
      add(Ruote::Exp::RawExpression)
      add(Ruote::Exp::DefineExpression)
      add(Ruote::Exp::SequenceExpression)
      add(Ruote::Exp::EchoExpression)
      add(Ruote::Exp::ParticipantExpression)
      add(Ruote::Exp::SetExpression)
      add(Ruote::Exp::SubprocessExpression)
      add(Ruote::Exp::ConcurrenceExpression)
      add(Ruote::Exp::ConcurrentIteratorExpression)
      add(Ruote::Exp::ForgetExpression)
      add(Ruote::Exp::UndoExpression)
      add(Ruote::Exp::RedoExpression)
      add(Ruote::Exp::CancelProcessExpression)
      add(Ruote::Exp::WaitExpression)
      add(Ruote::Exp::ListenExpression)
      add(Ruote::Exp::CommandExpression)
      add(Ruote::Exp::IteratorExpression)
      add(Ruote::Exp::CursorExpression)
      add(Ruote::Exp::IfExpression)
      add(Ruote::Exp::EqualsExpression)
      add(Ruote::Exp::ReserveExpression)
      add(Ruote::Exp::SaveExpression)
      add(Ruote::Exp::RestoreExpression)
      add(Ruote::Exp::NoOpExpression)
      add(Ruote::Exp::ApplyExpression)
      add(Ruote::Exp::AddBranchesExpression)
      add(Ruote::Exp::ErrorExpression)
      add(Ruote::Exp::IncExpression)
      add(Ruote::Exp::WhenExpression)
      add(Ruote::Exp::CronExpression)
    end

    # Returns the expression class for the given expression name
    #
    def expression_class (exp_name)

      @map[exp_name]
    end

    protected

    def add (exp_class)

      exp_class.expression_names.each { |n| @map[n] = exp_class }
    end
  end
end

