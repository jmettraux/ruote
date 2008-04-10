#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
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
# $Id: workitem.rb 3556 2006-11-13 04:15:52Z jmettraux $
#

#
# Made in Japan
#
# John Mettraux at OpenWFE dot org
#

require 'openwfe/workitem'
require 'openwfe/engine/engine'

#include OpenWFE


module OpenWFE

    def trace_flow (process_definition)

        li = LaunchItem.new process_definition

        engine = Engine.new

        i = 0

        engine.register_participant(".*") do |workitem|

            puts "-- #{i} ------------------------------------------------------------------------"
            puts
            puts " participant '#{workitem.participant_name}' received workitem :"
            puts 
            puts workitem.to_s
            puts
            puts "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" 
            puts
            puts " expression pool state :"
            #puts 
            puts engine.get_expression_storage.to_s
            puts
            #puts

            i = i + 1
        end

        engine.launch li
    end

end

