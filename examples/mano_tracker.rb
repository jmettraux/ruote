
# Copyright (c) 2001-2009, John Mettraux, jmettraux@gmail.com
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


# see
# http://groups.google.com/group/openwferu-users/browse_frm/thread/81294030fc52cd04
# for the context of this example

require 'rubygems'

require 'openwfe/workitem'
#require 'openwfe/engine/engine'
require 'openwfe/engine/fs_engine'
require 'openwfe/worklist/storeparticipant'


#
# The process definition
# (using a programmatic process definition instead of an XML process definition)

TRACKER_DEF = OpenWFE.process_definition :name => 'mano_tracker' do

  _loop do
    participant '${f:creative}'
    participant '${f:analyst}'

    _break :if => '${f:done}'
      #
      # loops until the analyst sets the value of the field
      # 'done' to true.
  end
    #
    # 'loop' and 'break' are ruby keywords, they have to be
    # preceded by an underscore '_' to be used in their ruote sense.
end

#
# prepare the engine and the participants

ANALYSTS = %w[ Mano Matt Moe ]
CREATIVES = %w[ Jami Jeff John Jeremy ]

#
# instantiate the engine (a transient one is sufficient for the example)

ac = {}
ac[:definition_in_launchitem_allowed] = true

#$engine = OpenWFE::Engine.new(ac)
  # no persistence

$engine = OpenWFE::FsPersistedEngine.new(ac)
  # persisted to work/

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

  li = OpenWFE::LaunchItem.new(TRACKER_DEF)
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
  'Mano',
  'Jami',
  'new logo for company',
  'http://openwferu.rubyforge.org/images/openwfe-logo.png')

puts "launched tracker process #{fei.workflow_instance_id}"

#
# the creative Jami can browse the items he has to treat with :

jami_store = $creative_stores['Jami']

first_fei = nil

jami_store.each do |fei, workitem|
  first_fei ||= fei
  puts " - #{fei.workflow_instance_id} -- #{workitem.title}"
end

workitem = jami_store[first_fei]

# play with the workitem and then send it back to the engine

workitem.item_url = "some other url"
  #
  # actually just changing the item_url

jami_store.forward(workitem)

# ...

