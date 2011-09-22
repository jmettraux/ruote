
#
# testing ruote
#
# Wed Sep 16 16:28:36 JST 2009
#

#require 'profile'

require 'rubygems'

require File.dirname(__FILE__) + '/../path_helper'
require File.dirname(__FILE__) + '/../functional/engine_helper'

ac = {
  #:definition_in_launchitem_allowed => true
}

engine = determine_engine_class(ac).new(ac)

#puts
#p engine.class
#puts

#N = 10_000
N = 1_000
#N = 300

#engine.context[:noisy] = true

launched = nil
reached = nil
count = 0

engine.register_participant :alpha do |workitem|
  reached ||= Time.now
  count += 1
end

launched = Time.now

#wfid = engine.launch(
#  Ruote.process_definition :name => 'ci' do
#    concurrent_iterator :branches => N.to_s do
#      alpha
#    end
#  end
#)
wfid = engine.launch(
  Ruote.process_definition(:name => 'ci') do
    concurrent_iterator :branches => 10 do
      concurrent_iterator :branches => 10 do
        concurrent_iterator :branches => 10 do
          alpha
        end
      end
    end
  end
)

engine.logger.wait_for([ [ :processes, :terminated, { :wfid => wfid } ] ])

puts "whole process took #{Time.now - launched} s"
puts "workitem reached first participant after #{reached - launched} s"
puts "seen #{count} workitems"
puts "#{N} branches"

engine.stop

