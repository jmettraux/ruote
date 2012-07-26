
#
# test/idle.rb
#
# Thu Jul 26 20:34:53 JST 2012
#
# light load, for a few hours
#

require 'rufus-json/automatic'
require 'ruote'
require File.expand_path('../../functional/storage_helper', __FILE__)

sto = determine_storage({})

dboard = Ruote::Dashboard.new(Ruote::Worker.new(sto))
dboard.noisy = ENV['NOISY'].to_s == 'true'

dboard.register 'alpha' do |workitem|
  sleep(60.0 * rand)
end

loop do
  dboard.launch(Ruote.define do
    21.times { alpha }
  end)
  sleep(60.0 * 10 * rand)
end

