
#
# testing ruote
#
# Tue Jun 15 09:07:58 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/part/storage_participant'


class FtStorageCopyTest < Test::Unit::TestCase
  include FunctionalBase

  def test_copy_to_hash_storage

    @engine.register_participant '.+', Ruote::StorageParticipant

    #noisy

    wfid = @engine.launch(Ruote.process_definition do
      sequence do
        alpha :timeout => '2d'
      end
    end)

    wait_for(:alpha)

    target = Ruote::HashStorage.new
    source = @engine.context.storage

    #count = source.copy_to(target, :verbose => true)
    count = source.copy_to(target)

    assert_equal 8, count
    assert_equal source.ids('expressions'), target.ids('expressions')
  end

  def test_copy_from_hash_storage

    engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))

    engine.register_participant '.+', Ruote::StorageParticipant

    #engine.context.logger.noisy = true

    wfid = engine.launch(Ruote.process_definition do
      sequence do
        alpha :timeout => '2d'
      end
    end)

    engine.wait_for(:alpha)

    source = engine.context.storage
    target = @engine.context.storage

    #count = source.copy_to(target, :verbose => true)
    count = source.copy_to(target)

    assert_equal 8, count
    assert_equal source.ids('expressions'), target.ids('expressions')
    assert_not_nil @engine.process(wfid)
  end
end

