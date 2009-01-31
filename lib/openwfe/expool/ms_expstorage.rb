#
#--
# Copyright (c) 2009, John Mettraux, OpenWFE.org
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

require 'fileutils'
require 'openwfe/expool/expstorage'


module OpenWFE

  class MarshalFileExpressionStorage
    include ServiceMixin
    include OwfeServiceLocator
    include ExpressionStorageBase

    def initialize (service_name, application_context)

      service_init(service_name, application_context)

      @basepath = 'work/expool'

      observe_expool
    end

    def []= (fei, fexp)

      d, fn = filename_for(fei)

      FileUtils.mkdir_p(d) unless File.exist?(d)

      File.open("#{d}/#{fn}", 'w') { |f| f.write(Marshal.dump(fexp)) }
    end

    def [] (fei)

      fn = filename_for(fei, true)
      return nil unless File.exist?(fn)
      fexp = File.open(fn, 'r') { |f| Marshal.load(f.read) }
      fexp.application_context = @application_context
      fexp
    end

    def delete (fei)

      fn = filename_for(fei, true)
      FileUtils.rm_f(fn)
    end

    # TODO : what about reload ?

    protected

    def dir_for (wfid)

      wfid = FlowExpressionId.to_parent_wfid(wfid)
      a_wfid = get_wfid_generator.split_wfid(wfid)

      "#{@basepath}/#{a_wfid[-2]}/#{a_wfid[-1]}/"
    end

    def filename_for (fei, join=false)

      r = if fei.wfid == '0'
        [ @basepath, 'engine_environment.ms' ]
      else
        [
          dir_for(fei.wfid),
          "#{fei.workflow_instance_id}__#{fei.expression_id}_#{fei.expression_name}.ms"
        ]
      end

      join ? "#{r.first}/#{r.last}" : r
    end

  end
end

