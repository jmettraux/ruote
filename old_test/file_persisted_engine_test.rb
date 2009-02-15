#
#--
# Copyright (c) 2007-2009, Urbacon Ltd.
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

#
# "made in Canada"
#
# Matt Zukowski at roughest.net
# John Mettraux at openwfe.org
#

require 'test/unit'
require 'fileutils'

require 'rubygems'

$:.unshift(File.dirname(__FILE__) + '/../lib') \
  unless $:.include?(File.dirname(__FILE__) + '/../lib')

require 'openwfe/engine/file_persisted_engine'


# Tests to assert correct functionality of the FilePersistedEngine.
#
class FilePersistedEngineTest < Test::Unit::TestCase

  # Test to make sure that persistence data is stored in the specified
  # working directory.
  #
  def test_custom_working_directory

    workdir = "test_custom_working_directory-#{Time.now.to_i}-#{rand(99999)}"
    FileUtils.rm_rf(workdir) if File.exists?(workdir)

    engine = OpenWFE::FilePersistedEngine.new(:work_directory => workdir)

    assert(
      File.exists?(workdir),
      "Custom working directory '#{workdir}' was not created by #{engine.class} during testing!")

    FileUtils.rm_rf(workdir)
  end
end

