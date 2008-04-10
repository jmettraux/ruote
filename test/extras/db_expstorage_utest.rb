
require 'test/unit'
require 'rubygems'
require 'mocha'

require 'rutest_utils'
require 'extras/active_connection'
require 'openwfe/flowexpressionid'
require 'openwfe/extras/expool/dbexpstorage'


class FakeExpression

    attr_accessor :fei
    attr_accessor :message
    attr_accessor :application_context

    def self.create (exp_id, wfid, msg)

        fei = new_fei
        fei.expression_id = exp_id
        fei.wfid = wfid

        fe = self.new
        fe.fei = fei
        fe.message = msg

        fe
    end
end

class VeryFakeExpression < FakeExpression
end

class FakeExpressionMap

    def get_expression_classes (kind)
        if kind == VeryFakeExpression
            [ VeryFakeExpression ]
        else
            [ VeryFakeExpression, FakeExpression ]
        end
    end
end


class DbExpressionStorageUnitTest < Test::Unit::TestCase

    def setup

        expool = mock
        expool.expects(:add_observer).times(2)

        ac = {}
        ac['expressionPool'] = expool
        ac['expressionMap'] = FakeExpressionMap.new

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

        assert_equal 'kthxbai', fe.message

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
            :include_classes => FakeExpression).each do |fexp|

            assert_kind_of FakeExpression, fexp
            count += 1
        end
        assert_equal 2, count

        store_fake '0', '20071127-c', 'kthxbai 2', true
        store_fake '0', '20071127-d', 'kthxbai 3', true

        count = 0
        @storage.find_expressions(
            :include_classes => FakeExpression).each do |fexp|

            assert_kind_of FakeExpression, fexp
            count += 1
        end
        assert_equal 4, count

        count = 0
        @storage.find_expressions(
            :include_classes => VeryFakeExpression).each do |fexp|

            assert_kind_of VeryFakeExpression, fexp
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

            clazz = other_class ? VeryFakeExpression : FakeExpression
            fe = clazz.create exp_id, wfid, msg

            @storage[fe.fei] = fe

            fe
        end
end

