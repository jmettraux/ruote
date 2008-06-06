#
#--
# Copyright (c) 2007, John Mettraux OpenWFE.org
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
# $Id: definitions.rb 2725 2006-06-02 13:26:32Z jmettraux $
#

#
# "made in Japan"
#
# John Mettraux at openwfe.org
#

#
# see
# http://groups.google.com/group/openwferu-users/browse_frm/thread/81294030fc52cd04
# for the context of this example
#

require 'rubygems'

#require 'openwfe/engine/engine'
require 'openwfe/engine/file_persisted_engine'
require 'openwfe/expressions/raw_prog'
require 'openwfe/worklist/storeparticipant'


#
# The process definition
# (using a programmatic process definition instead of an XML process definition)

class TrackerDefinition < OpenWFE::ProcessDefinition
  def make

    _loop do
      participant "${f:creative}"
      participant "${f:analyst}"

      _break :if => "${f:done}"
        #
        # loops until the analyst sets the value of the field
        # 'done' to true.
    end
      #
      # 'loop' and 'break' are ruby keywords, they have to be
      # preceded by an underscore '_' to be used in their
      # OpenWFEru sense.
  end
end

#
# prepare the engine and the participants

ANALYSTS = [ "Mano", "Matt", "Moe" ]
CREATIVES = [ "Jamie", "Jeff", "John", "Jeremy" ]

#
# instantiate the engine (a transient one is sufficient for the example)

#$engine = OpenWFE::Engine.new
  # no persistence

#$engine = OpenWFE::FilePersistedEngine.new
  # persistence, but no caching (worst performance)

$engine = OpenWFE::CachedFilePersistedEngine.new
  # persistence and performance

$analyst_stores = {}
$creative_stores = {}
  #
  # gathering the stores for our fictitious organization

def add_stores (names, store_map)
  names.each do |name|
    #hp = OpenWFE::HashParticipant.new
    #$engine.register_participant(name, hp)
    hp = $engine.register_participant(name, OpenWFE::YamlParticipant)
    store_map[name] = hp
  end
end

add_stores(ANALYSTS, $analyst_stores)
add_stores(CREATIVES, $creative_stores)

#
# a quick method for launching a tracker process instance
#
def launch_tracker (analyst_name, creative_name, title, item_url)

  li = LaunchItem.new(TrackerDefinition)
    #
    # preparing a lunchitem ;) around our TrackerDefinition

  li.analyst = analyst_name
  li.creative = creative_name
  li.title = title
  li.item_url = item_url
    #
    # filling the workitem with attributes

  $engine.launch(li)
end

# the system is ready...


#
# (...)
#
# Later it can be used as follow

fei = launch_tracker(
  "Mano",
  "Jamie",
  "new logo for company",
  "http://openwferu.rubyforge.org/images/openwfe-logo.png")

puts "launched tracker process #{fei.workflow_instance_id}"

#
# the creative Jamie can browse the items he has to treat with :

jamie_store = $analyst_stores["Jamie"]

first_fei = nil

jamie_store.each do |fei, workitem|
  first_fei = fei unless fei
  puts " - #{fei.workflow_instance_id} -- #{workitem.title}"
end

workitem = jamie_store[first_fei]

# play with the workitem and then send it back to the engine

workitem.item_url = "some other url"
  #
  # actually just changing the item_url

jamie_store.forward(workitem)

# ...

