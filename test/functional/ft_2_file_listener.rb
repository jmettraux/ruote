
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Since Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/base'

require 'openwfe/listeners/listeners'
require 'openwfe/participants/participants'


class FtFileListenerTest < Test::Unit::TestCase
  include FunctionalBase

  def test_file_listener

    pdef = OpenWFE.process_definition :name => 'test' do
      sequence do
        participant :fp
        echo 'done.'
      end
    end

    FileUtils.mkdir('work/in') unless File.exist?('work/in')

    fp = @engine.register_participant(:fp, OpenWFE::FileParticipant)
    @engine.register_listener(OpenWFE::FileListener, :freq => '300')

    fei = @engine.launch(pdef)
    sleep 0.350

    assert_equal '', @tracer.to_s

    Dir['work/out/*.yaml'].each { |f| FileUtils.mv(f, 'work/in/') }

    sleep 0.700

    assert_equal 'done.', @tracer.to_s
  end
end

