
require 'test/unit'
require 'rubygems'
require 'mocha'

require File.dirname(__FILE__) + '/active_connection'

require 'rutest_utils'
require 'openwfe/flowexpressionid'
require 'openwfe/expressions/flowexpression'
require 'openwfe/extras/expool/db_expstorage'


#class ActiveRecord::Base
#  def unserialize_attribute(attr_name)
#    p attr_name
#    p @attributes
#    unserialized_object = object_from_yaml(@attributes[attr_name])
#    if unserialized_object.is_a?(self.class.serialized_attributes[attr_name]) || unserialized_object.nil?
#      @attributes.frozen? ? unserialized_object : @attributes[attr_name] = unserialized_object
#    else
#      raise(
#        SerializationTypeMismatch,
#        "#{attr_name} was supposed to be a #{self.class.serialized_attributes[attr_name]}, but was a #{unserialized_object.class.to_s}")
#    end
#  end
#  def object_from_yaml (s)
#    p s
#    return s unless s.is_a?(String) && s =~ /^---/
#    begin
#      YAML::load(s)
#    rescue Exception => e
#      p e
#      return s
#    end
#  end
#end
  #
  # peeking at the deYAMLisation problems


class OpenWFE::FlowExpression

  def self.create (exp_id, wfid, msg)

    new_exp(
      OpenWFE::FlowExpressionId.new_fei(
        :workflow_instance_id => wfid, :expression_id => exp_id),
      nil,
      nil,
      {},
      { 'message' => msg })
  end
end

class OpenWFE::OtherExpression < OpenWFE::FlowExpression
end

class FakeExpressionMap
  def get_expression_classes (kind)
    if kind == OpenWFE::OtherExpression
      [ OpenWFE::OtherExpression ]
    else
      [ OpenWFE::OtherExpression, OpenWFE::FlowExpression ]
    end
  end
end


class DbExpressionStorageUnitTest < Test::Unit::TestCase

  def setup

    expool = mock
    expool.expects(:add_observer).times(2)

    ac = {}
    ac[:s_expression_pool] = expool
    ac[:s_expression_map] = FakeExpressionMap.new

    @storage = OpenWFE::Extras::DbExpressionStorage.new 'expstorage', ac
  end

  def teardown

    OpenWFE::Extras::Expression.destroy_all
  end

  def test_0

    assert_equal 0, @storage.size

    fe = store_fake '0.1', '20071127-a', 'kthxbai'

    @storage[fe.fei] = fe

    assert_equal 1, @storage.size

    fei = fe.fei.dup

    assert @storage.has_key?(fei)

    fe = @storage[fei]

    assert_equal 'kthxbai', fe.attributes['message']

    @storage.delete fei

    assert_equal 0, @storage.size

    store_fake '0', '20071127-a', 'kthxbai 0'
    store_fake '0.0', '20071127-a', 'kthxbai 1'

    assert_equal 2, @storage.size

    @storage.purge

    assert_equal 0, @storage.size
  end

  def test_1

    store_fake '0', '20071127-a', 'kthxbai 0'
    store_fake '0', '20071127-b', 'kthxbai 1'

    assert_equal 2, @storage.size

    count = 0
    @storage.find_expressions(
      :include_classes => OpenWFE::FlowExpression).each do |fexp|

      assert_kind_of OpenWFE::FlowExpression, fexp
      count += 1
    end
    assert_equal 2, count

    store_fake '0', '20071127-c', 'kthxbai 2', true
    store_fake '0', '20071127-d', 'kthxbai 3', true

    count = 0
    @storage.find_expressions(
      :include_classes => OpenWFE::FlowExpression).each do |fexp|

      assert_kind_of OpenWFE::FlowExpression, fexp
      count += 1
    end
    assert_equal 4, count

    count = 0
    @storage.find_expressions(
      :include_classes => OpenWFE::OtherExpression).each do |fexp|

      assert_kind_of OpenWFE::OtherExpression, fexp
      count += 1
    end
    assert_equal 2, count
  end

  def test_2

    store_fake '0', '20071001-A', 'kthxbai -1'
    store_fake '0', '20071127-a', 'kthxbai 0'
    store_fake '0', '20071127-b', 'kthxbai 1'
    store_fake '0', '20071127-c', 'kthxbai 2'
    store_fake '0', '20071127-d', 'kthxbai 3', true

    count = 0
    @storage.find_expressions.each do |fexp|
      count += 1
    end
    assert_equal 5, count

    count = 0
    @storage.find_expressions(:wfid_prefix => '200711').each do |fexp|

      assert fexp.fei.wfid.match('^200711')
      count += 1
    end
    assert_equal 4, count
  end

  protected

    def store_fake (exp_id, wfid, msg, other_class=false)

      clazz = other_class ? OpenWFE::OtherExpression : OpenWFE::FlowExpression
      fe = clazz.create exp_id, wfid, msg

      @storage[fe.fei] = fe

      fe
    end
end

