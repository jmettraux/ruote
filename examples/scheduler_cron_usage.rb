
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

i = 0

scheduler.schedule("1-60 * * * *") do
    p "minute ##{i}"
    i = i + 1
end

scheduler.schedule_in("2m10s") do
    p "after 2 minutes and 10 seconds stopping the scheduler and exiting..."
    scheduler.stop
end
    #
    # using a regular "at" job to stop the scheduler after 4 minutes

scheduler.join
    #
    # align the thread of this program to the scheduler thread
    # i.e. exit program only when scheduler terminates

