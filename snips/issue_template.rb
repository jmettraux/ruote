
# a template for issue reporting

# Gemfile
#
# ---8<---
# source :rubygems
#
# gem 'yajl-ruby', :require => 'yajl'
# #gem 'ruote'
# gem 'ruote', :git => 'git://github.com/jmettraux/ruote.git'
# --->8---

require 'pp'
require 'ruote'

ruote =
  Ruote::Dashboard.new(
    Ruote::Worker.new(
      Ruote::HashStorage.new))
  #
  # or
  #
# require 'ruote/storage/fs_storage'
#
# ruote =
#   Ruote::Dashboard.new(
#     Ruote::Worker.new(
#       Ruote::FsStorage.new("ruote_issue_work_#{Time.now.to_i}")))

ruote.noisy = (ENV['NOISY'] == 'true')


#
# define participant classes (if needed)
#

class MyParticipant < Ruote::Participant

  def on_workitem
    puts "#{self.class} saw workitem for #{workitem.participant_name}"
    reply
  end
end


#
# register participants
#

ruote.register do
  participant 'alpha', MyParticipant
  catchall MyParticipant
end


#
# define process
#

pdef =
  Ruote.define do
    alpha
    bravo
  end


#
# run process
#

wfid = ruote.launch(pdef)

r = ruote.wait_for(wfid)
  # exit the ruby process only when process is over or got into an error

if r['action'] == 'error_intercepted'

  puts "*** error, the process stopped ***"

  p ruote.ps(wfid)
end

