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

#require 'ruby_parser'
    #
    # For now, ruby_parser plays with StringIO, that breaks lots of things,
    # so no. 
    # (http://www.zenspider.com/pipermail/parsetree/2008-April/000026.html)

require 'parse_tree'


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

        private

            def self.do_check (sexp)

                #
                # intercepting raw "exit"

                raise SecurityError.new("'exit' found") \
                    if sexp == [ :vcall, :exit ]
                raise SecurityError.new("'abort' found") \
                    if sexp == [ :vcall, :abort ]

                #
                # global vars are off limits

                raise SecurityError.new("global vars reference found") \
                    if sexp == :gvar

                #
                # check children

                return unless sexp.is_a?(Array)

                sexp.each { |s| do_check(s) }
            end

            #
            # just making sure we have a sexp
            #
            def self.parse (sruby)

                return sruby if sruby.is_a?(Array)

                #RubyParser.new.parse(sruby).to_a
                ParseTree.translate sruby
            end
    end

end

