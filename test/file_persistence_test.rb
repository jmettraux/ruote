
require 'test/unit'

require 'rubygems'

$:.unshift( File.dirname(__FILE__) + '/../lib' ) unless \
  $:.include?( File.dirname(__FILE__) + '/../lib' )

require 'openwfe/engine/engine'
require 'openwfe/expool/expstorage'
require 'openwfe/expool/yaml_expstorage'


class FilePersistenceTest < Test::Unit::TestCase

  def setup
    @engine = OpenWFE::Engine.new
  end

  def teardown
    @engine.stop
  end

  def ac
    @engine.application_context
  end

  #
  # test persistence using yaml
  def test_yaml_persistence
    fes = OpenWFE::YamlFileExpressionStorage.new("yaml", ac)
    test_persistence(fes)
  end

  #
  # flow expression check
  def test_flow_expression
    fei = new_fei()
    fes = OpenWFE::YamlFileExpressionStorage.new "yaml", ac
    fe = OpenWFE::SequenceExpression.new_exp fei, nil, nil, nil, nil
    test_persistence(fes,fe)
  end

  def test_path_splitting

    fei = new_fei
    fes = OpenWFE::YamlFileExpressionStorage.new("yaml", ac)
    class << fes
      public :compute_file_path
    end
    path = fes.compute_file_path fei
    a = fes.class.split_file_path path

    assert_equal a[0], fei.wfid
    assert_equal a[1], fei.expression_id
    assert_equal a[2], fei.expression_name
  end

  def test_other_workdir

    context = ac
    context[:work_directory] = "work2"

    fei = new_fei()
    fes = OpenWFE::YamlFileExpressionStorage.new("yaml", ac)
    #fe = SequenceExpression.new(fei, nil, nil, nil, nil)
    #fes[fei] = fe

    assert File.exist?("work2")

    FileUtils.rm_rf("work2")
    assert (not File.exist?("work2"))
  end

  #
  # test UTF-8 data persistence
  #
  def test_utf8_with_file

    workflow_definition_name = "みんなにARIGATOU★☆に関する最新の情報公開"
    fei = new_fei workflow_definition_name
    fes = OpenWFE::YamlFileExpressionStorage.new "yaml", ac
    fe = OpenWFE::SequenceExpression.new_exp fei, nil, nil, nil, nil

    loaded = test_persistence(fes, fe)

    #puts
    #puts fei.workflow_definition_name
    #puts loaded.fei.workflow_definition_name

    assert_equal(
      loaded.fei.workflow_definition_name, fei.workflow_definition_name)
  end


  protected

    def test_persistence (fes, fe=nil)

      fei = new_fei()
      fes.delete(fei) if (fes.has_key?(fei))

      raw = fe ? \
        fe : \
        OpenWFE::RawExpression.new_raw(fei, 'parent', 'env', nil, nil)

      assert(
        !fes.has_key?(fei),
        "they key is present in the file system. "+
        "Maybe a previous test did not delete the ") # なに ?

      fes[fei] = raw
      assert fes.has_key?(fei)

      loaded = fes[fei]

      fes.delete(fei)
      assert !(fes.has_key?(fei))

      loaded
    end

    def new_fei (definition_name=nil)

      fei = OpenWFE::FlowExpressionId.new
      fei.owfe_version = OpenWFE::OPENWFERU_VERSION
      fei.engine_id = 'this'
      fei.initial_engine_id = 'that'
      fei.workflow_definition_url = 'http://test/test.xml'
      fei.workflow_definition_name = definition_name || 'test'
      fei.workflow_definition_revision = '1.0'
      fei.workflow_instance_id = @engine.get_wfid_generator.generate
      fei.expression_name = 'do-test'
      fei.expression_id = '0.0'
      fei
    end

end
