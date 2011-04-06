
#
# testing ruote
#
# Wed Apr  6 06:52:53 JST 2011
#
# Santa Barbara
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote'
#require 'ruote/participant'


class FtRevParticipantTest < Test::Unit::TestCase
  include FunctionalBase

  def test_x

    dir = [
      'rev_participant', $$, Time.now.to_f
    ].collect { |e| e.to_s }.join('_')

    FileUtils.mkdir(dir)

    File.open(dir + '/alpha.rb', 'wb') do |f|
      f.write(%{
def consume(workitem)
  (workitem.fields['seen'] ||= []) << 'alpha'
  reply_to_engine(workitem)
end
      })
    end
    File.open(dir + '/alpha__z.rb', 'wb') do |f|
      f.write(%{
def consume(workitem)
  (workitem.fields['seen'] ||= []) << 'alpha__z'
  reply_to_engine(workitem)
end
      })
    end

    @engine.register do
      catchall Ruote::RevParticipant, :dir => dir
    end

    pdef = Ruote.process_definition 'x', :revision => 'y' do
      alpha :rev => 'z'
      alpha
    end

    #@engine.noisy = true

    wfid = @engine.launch(pdef)

    r = @engine.wait_for(wfid)

    assert_equal %w[ alpha__z alpha ], r['workitem']['fields']['seen']

  ensure
    FileUtils.rm_rf(dir)
  end
end

