#
#--
# Copyright (c) 2008, John Mettraux, OpenWFE.org
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

require 'ruby_parser' #gem "rogue_parser"

#begin
#  require 'parse_tree'
#rescue LoadError => le
#  puts "...couldn't find or load the gem 'ParseTree'"
#end


module OpenWFE

  #
  # a local exception for when 'illicit' code is spotted
  #
  class SecurityError < RuntimeError
  end

  #
  # Various static methods for checking ruby code coming into the system.
  #
  # Very naive for now, but aims to improve.
  #
  module TreeChecker

    #
    # Check the given Ruby code string, and will raise an exception
    # whenever there's some illicit code...
    #
    def self.check (sruby)

      sexp = parse sruby
      #p sexp
      do_check sexp
    end

    #
    # Checks whether only single statement got passed (avoiding
    # "1 == 2; puts 'doing evil stuff'"
    #
    def self.check_conditional (sruby)

      sexp = parse sruby

      #p sexp

      raise SecurityError.new("more than 1 statement") \
        if sexp.first == :block

      raise SecurityError.new("assignment found") \
        if sexp.first == :lasgn

      do_check sexp
    end

    #
    # Used by RevalExpression and the dollar substitution
    #
    def self.check_reval (sruby)

      sexp = parse sruby

      do_check sexp
    end

    private

      def self.do_check (sexp)

        #
        # intercepting some insecure methods

        [
          :exit, :exit!, :abort,
          :system, :eval, :trap, :fork, :syscall
        ].each do |m|
          exclude_method sexp, m
        end

        #
        # no definition or reopening of modules and classes

        exclude_class_and_mod_defs sexp

        #
        # no module_eval or instance_eval

        exclude_evals sexp

        #
        # off limits constants

        [ :File, :FileUtils, :Process, :IO ].each do |m|
          exclude_call_on_const sexp, m
        end

        #
        # global vars are off limits

        raise SecurityError.new("global var reference found") \
          if sexp == :gvar

        raise SecurityError.new("alias is not allowed") \
          if sexp == :alias

        #
        # check children

        return unless sexp.is_a?(Array)

        sexp.each { |s| do_check s }
      end

      def self.exclude_method (sexp, meth)

        return unless sexp.is_a?(Array)

        head = sexp[0, 2]

        raise SecurityError.new("'#{meth}' found") \
          if (head == [ :vcall, meth ] or head == [ :fcall, meth ])
      end

      def self.exclude_call_on_const (sexp, class_or_module)

        return unless sexp.is_a?(Array)

        head = sexp[0, 2]

        raise SecurityError.new(
          "cannot call method on '#{class_or_module}'"
        ) if head == [ :call, [ :const, class_or_module ] ]
      end

      def self.exclude_evals (sexp)

        return unless sexp.is_a?(Array)

        m = sexp[2]

        return unless (m == :module_eval or m == :instance_eval)

        raise SecurityError.new("evals are not allowed") \
          if sexp[0] == :call
      end

      def self.exclude_class_and_mod_defs (sexp)

        return unless sexp.is_a?(Array)

        return unless [ :class, :sclass, :module ].include?(sexp[0])

        return if sexp[2] == [
          :colon2, [ :const, :OpenWFE ], :ProcessDefinition ]

        raise SecurityError.new(
          "reopening or definition of class or module not allowed")
      end

      #
      # just making sure we have a sexp
      #
      def self.parse (sruby)

        return sruby if sruby.is_a?(Array)

        RubyParser.new.parse(sruby).to_a

        #return [] unless defined?(ParseTree)
        #ParseTree.translate sruby
      end
  end

end

