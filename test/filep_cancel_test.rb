
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Sun Nov 25 14:41:32 JST 2007
#

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'openwfe/def'
require 'openwfe/engine/file_persisted_engine'


class FilePersistenceAndCancel < Test::Unit::TestCase

  #def setup
  #end

  def teardown

    $OWFE_LOG.level = Logger::INFO

    FileUtils.rm_rf "work_filep"
  end

  class OpenWFE::YamlFileExpressionStorage
    public :compute_file_path
  end

  XMLDEF = <<XML
<process-definition name="simple_sequence" revision="1">
<description>
a tiny 'hello world' sequence
</description>
<sequence>
<set field="message" value="hello world !" />
<participant ref="bravo" />
<participant ref="alpha" />
</sequence>
</process-definition>
XML

  class TestDef0 < OpenWFE::ProcessDefinition
    sequence do
      alpha
      bravo
    end
  end

  def test_0

    ac = {
      :work_directory => "work_filep",
      :definition_in_launchitem_allowed => true
    }

    @engine = OpenWFE::FilePersistedEngine.new ac

    #fei = @engine.launch TestDef0
    fei = @engine.launch XMLDEF

    sleep 0.350

    assert File.exist?(path0(fei))

    @engine.cancel_process fei.wfid

    sleep 0.350

    assert ( ! File.exist?(path0(fei)))
    #assert ( ! File.exist?("./work/ejournal/#{fei.wfid}.ejournal"))

    @engine.stop

    FileUtils.rm_rf "work_filep"
  end

  def test_1

    ac = {
      :work_directory => "work_filep",
      :definition_in_launchitem_allowed => true
    }

    @engine = OpenWFE::CachedFilePersistedEngine.new ac

    #$OWFE_LOG.level = Logger::DEBUG

    #fei = @engine.launch TestDef0
    fei = @engine.launch XMLDEF

    sleep 0.900
      # it's a bit longish...

    #puts path1(fei)
    assert File.exist?(path1(fei))

    @engine.cancel_process fei.wfid

    sleep 0.900

    assert ( ! File.exist?(path1(fei)))
    #assert ( ! File.exist?("./work/ejournal/#{fei.wfid}.ejournal"))

    @engine.stop
  end

  protected

    def path0 (fei)

      @engine.get_expression_storage.compute_file_path(fei)
    end

    def path1 (fei)

      @engine.ac[OpenWFE::S_EXPRESSION_STORAGE + ".1"].compute_file_path(fei)
    end
end
