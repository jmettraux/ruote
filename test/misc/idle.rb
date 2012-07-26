
#
# test/idle.rb
#
# Thu Jul 26 20:34:53 JST 2012
#
# used when observing ruote's idle behaviour (checking it's not polling too
# much)
#

require 'rufus-json/automatic'
require 'ruote'
require File.expand_path('../../functional/storage_helper', __FILE__)

sto = determine_storage({})

dboard = Ruote::Dashboard.new(Ruote::Worker.new(sto))
#dboard.noisy = ENV['NOISY'].to_s == 'true'

dboard.join

