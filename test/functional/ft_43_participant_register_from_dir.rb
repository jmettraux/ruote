
#
# testing ruote
#
# Sun Jul 11 16:56:53 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')


class FtParticipantRegistrationFromDirTest < Test::Unit::TestCase
  include FunctionalBase

  def test_register_from_dir

    dir = "_participants_#{Time.now.to_f}_#{$$}"

    FileUtils.mkdir(dir)

    File.open("#{dir}/kilroy.rb", 'wb') do |f|
      f.write(%{
        class KilroyParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
          end
          def consume (workitem)
            workitem.fields['kilroy'] = 'was here'
            reply(workitem)
          end
        end
      })
    end
    File.open("#{dir}/toto.rb", 'wb') do |f|
      f.write(%{
        class TotoParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
          end
          def consume (workitem)
            workitem.fields['toto'] = 'was here too'
            reply(workitem)
          end
        end
      })
    end

    @engine.register_from_dir dir

    assert_equal [ '^kilroy$', '^toto$' ], @engine.context.plist.names

    wfid = @engine.launch(Ruote.define { kilroy; toto })
    r = wait_for(wfid)

    assert_equal(
      { 'kilroy' => 'was here', 'toto' => 'was here too' },
      r['workitem']['fields'])

    FileUtils.rm_rf(dir) rescue nil
  end

  def test_register_from_dir_with_participant_regex

    dir = "_participants_#{Time.now.to_f}_#{$$}"

    FileUtils.mkdir(dir)

    File.open("#{dir}/a.rb", 'wb') do |f|
      f.write(%{
        class ThatParticipant
          include Ruote::LocalParticipant
          def self.participant_regex
            /^that\\_.+/
          end
          def initialize (opts)
          end
          def consume (workitem)
            (workitem.fields['seen'] ||= []) << workitem.participant_name
            reply(workitem)
          end
        end
      })
    end

    @engine.register_from_dir dir

    assert_equal [ '^that\_.+' ], @engine.context.plist.names

    wfid = @engine.launch(Ruote.define { that_dog; that_cat })
    r = wait_for(wfid)

    assert_equal(
      %w[ that_dog that_cat ],
      r['workitem']['fields']['seen'])

    FileUtils.rm_rf(dir) rescue nil
  end

  def test_register_from_dir_with_order_prefix

    dir = "_participants_#{Time.now.to_f}_#{$$}"

    FileUtils.mkdir(dir)

    File.open("#{dir}/1_b.rb", 'wb') do |f|
      f.write(%{
        class UserDashParticipant
          include Ruote::LocalParticipant
          def self.participant_regex
            /^user-.+/
          end
          def initialize (opts)
          end
          def consume (workitem)
            (workitem.fields['seen'] ||= []) << workitem.participant_name
            reply(workitem)
          end
        end
      })
    end
    File.open("#{dir}/0_user-toto.rb", 'wb') do |f|
      f.write(%{
        class UserTotoParticipant
          include Ruote::LocalParticipant
          def initialize (opts)
          end
          def consume (workitem)
            (workitem.fields['seen'] ||= []) << workitem.participant_name
            reply(workitem)
          end
        end
      })
    end

    @engine.register_from_dir dir

    assert_equal [ '^user-toto$', '^user-.+' ], @engine.context.plist.names

    wfid = @engine.launch(Ruote.define {
      participant 'user-x'
      participant 'user-toto'
    })
    r = wait_for(wfid)

    assert_equal(
      %w[ user-x user-toto ],
      r['workitem']['fields']['seen'])

    FileUtils.rm_rf(dir) rescue nil
  end
end

