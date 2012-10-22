
#
# testing ruote
#
# Tue Jun 15 09:07:58 JST 2010
#

require File.expand_path('../base', __FILE__)

require 'ruote/part/storage_participant'


class FtStorageCopyTest < Test::Unit::TestCase
  include FunctionalBase

  def test_copy_to_hash_storage

    @dashboard.register_participant '.+', Ruote::StorageParticipant

    wfid = @dashboard.launch(Ruote.process_definition do
      sequence do
        alpha :timeout => '2d'
      end
    end)

    wait_for(:alpha)

    sleep 0.100 # making sure msgs have all been processed

    target = Ruote::HashStorage.new
    source = @dashboard.context.storage

    #count = source.copy_to(target, :verbose => true)
    count = source.copy_to(target)

    assert_equal 8, count
    assert_equal source.ids('expressions'), target.ids('expressions')
  end

  def test_copy_from_hash_storage

    dash = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new()))

    dash.noisy = ENV['NOISY'] == 'true'

    dash.register_participant '.+', Ruote::StorageParticipant

    wfid = dash.launch(Ruote.process_definition do
      sequence do
        alpha :timeout => '2d'
      end
    end)

    dash.wait_for(:alpha)

    sleep 0.100 # making sure msgs have all been processed

    source = dash.context.storage
    target = @dashboard.context.storage

    #count = source.copy_to(target, :verbose => true)
    count = source.copy_to(target)

    assert_equal 8, count
    assert_equal source.ids('expressions'), target.ids('expressions')
    assert_not_nil @dashboard.process(wfid)
  end
end

