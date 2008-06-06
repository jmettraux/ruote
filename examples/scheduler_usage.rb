
#
# showing how to use the scheduler
#

require 'rubygems'

require 'time'

require 'openwfe/util/scheduler'
include OpenWFE


def p (msg)
  t = Time.new
  puts "#{t.iso8601} -- #{msg}"
end
  #
  # a small method for displaying the time at the beginning
  # of each output line


scheduler = Scheduler.new
scheduler.start
  #
  # create a scheduler instance and start it

p "started scheduler"

scheduler.schedule_in("3s") do
  p "after 3 seconds"
end

scheduler.schedule_in("2s") do
  p "after 2 seconds"
end

scheduler.schedule_in("5500") do
  p "after 5500 ms stopping the scheduler and exiting..."
  scheduler.stop
end

#scheduler.schedule_at("x" do
#end

#scheduler.schedule_in("3M4h27m") do
#  p "3 months, 4 hours and 27 minutes... A bit too much"
#end
  #
  # showing what the time strings are capable of

scheduler.join
  #
  # align the thread of this program to the scheduler thread
  # i.e. exit program only when scheduler terminates

