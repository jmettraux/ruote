#
# testing extended observers
#

require File.expand_path('../base', __FILE__)

class FtObserversTest < Test::Unit::TestCase
  include FunctionalBase

  class MyObserver < Ruote::ProcessObserver
    class << self
      attr_accessor :flunk_count
    end

    # store me in the workitem, and register when we launched
    def on_launch(opts)
      MyObserver.flunk_count ||= 0

      opts[:fields].merge!(
        'observer' => MyObserver, 'launched_at' => Time.now
      )
    end

    # increment the class flunk counter
    def on_flunk(opts)
      if opts[:workitem].fields['observer']
        opts[:workitem].fields['observer'].flunk_count += 1
      end
    end

    # increment the replies field
    def on_reply(opts)
      opts[:workitem].fields['replies'] ||= 0
      opts[:workitem].fields['replies'] += 1
    end
  end

  # an observer that tries to mess with stuff, evil.
  class MyEvilObserver < Ruote::ProcessObserver
    # try to inject a new participant
    def on_launch(opts)
      @context.dashboard.register_participant 'gizmo' do |workitem|
        workitem.fields['quote'] = 'Bye-bye, Woof Woof.'
        flunk(workitem, IndexError, "Wrong movie")
      end

      opts[:pdef][2] << ["participant", {"ref"=>"gizmo"}, []]
    end

    # press away the real error
    def on_flunk(opts)
      opts[:workitem].fields['quote'] ||= 'Failure is not an option'
      opts[:error] = Exception.new("...")
    end

    def on_reply(opts)
      # pretty lethal
      opts[:workitem].fields.delete_if { |k,v|
        k.is_a?(String) && k != 'quote'
      }
    end
  end

  # setup the players and the board
  def process_definition
    @dashboard.register do
      participant 'houston' do |wi|
        wi.fields['messages'] ||= []

        if wi.fields['messages'].include? "Houston; we have a problem"
          wi.fields['messages'] << "You're doomed!"
          flunk(wi, EOFError, "mission failure") if wi.fields['flunk']

        else
          wi.fields['messages'] << "You're cleared for take-off"
        end
      end
      participant 'apollo_XI' do |wi|
        wi.fields['messages'] ||= []
        wi.fields['messages'] << "Houston; we have a problem"
      end
      participant 'launch' do |wi|
        wi.fields['rocket_launched'] = true
      end
    end
    
    Ruote.process_definition :name => "movie time!" do
      sequence do
        houston
        launch
        apollo_XI
        houston
      end
    end
  end

  def test_on_launch
    @dashboard.add_service('observer', MyObserver)
    wfid = @dashboard.launch process_definition
    res = @dashboard.wait_for(wfid)

    assert_not_nil res['workitem']
    assert_not_nil res['workitem']['fields']['launched_at']
  end
  
  def test_on_flunk
    MyObserver.flunk_count = 0 # just to be sure
    @dashboard.add_service('observer', MyObserver)
    wfid = @dashboard.launch process_definition, { 'flunk' => true }
    res = @dashboard.wait_for(wfid)

    assert_equal 1, MyObserver.flunk_count
    assert_equal 'mission failure', res['error']['message']
  end
  
  def test_on_reply
    @dashboard.add_service('observer', MyObserver)
    wfid = @dashboard.launch process_definition
    res = @dashboard.wait_for(wfid)

    assert_not_nil res['workitem']
    assert_equal 4, res['workitem']['fields']['replies']
  end


  def test_on_evil_launch
    @dashboard.add_service('observer', MyEvilObserver)
    wfid = @dashboard.launch process_definition
    res = @dashboard.wait_for(wfid)

    assert_not_nil res['workitem']
    # the evil observer should not have passed
    assert_nil res['workitem']['fields']['quote']
  end
  
  def test_on_evil_flunk
    @dashboard.add_service('observer', MyEvilObserver)
    wfid = @dashboard.launch process_definition, { 'flunk' => true }
    res = @dashboard.wait_for(wfid)

    # the evil observer should not have messed with the error message
    assert_not_equal '...', res['error']['message']
    
    # and should not have updated the workitem
    assert_not_equal 'Failure is not an option', res['msg']['workitem']['fields']['quote']
  end
  
  def test_on_evil_reply
    @dashboard.add_service('observer', MyEvilObserver)
    wfid = @dashboard.launch process_definition
    res = @dashboard.wait_for(wfid)

    # according to the evil observer, only 'quote' may remain
    assert_not_equal 1, res['workitem']['fields'].length
  end
end

