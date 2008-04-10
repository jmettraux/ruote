
#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Tue Feb 19 10:58:43 JST 2008
#

require 'rubygems'

require 'test/unit'
require 'fileutils'
require 'openwfe/def'
require 'openwfe/engine/file_persisted_engine'


class Back0916Test < Test::Unit::TestCase

    WORK = 'work_back'

    def setup

        FileUtils.rm_rf WORK
        FileUtils.mkdir WORK

        `cd work_back && tar xzvf ../test/expool_20031219_0916.tgz`

        ac = { :work_directory => WORK }

        @engine = OpenWFE::FilePersistedEngine.new ac
    end

    def teardown

        $OWFE_LOG.level = Logger::INFO
        FileUtils.rm_rf WORK
    end

    def test_0

        $OWFE_LOG.level = Logger::DEBUG

        trace = []

        @engine.register_participant :alpha do
            trace << :alpha
        end

        @engine.reload

        ps = @engine.process_status "20080212-moshijuzuke" # an XML process
        #p ps.expressions.collect { |e| e.fei.to_s }
        exp = ps.expressions.first
        wi = exp.applied_workitem
        wi.message = "back from obsolesence"

        @engine.reply wi

        sleep 0.350

        assert_equal [ :alpha ], trace

        ps = @engine.process_status "20080212-moshijuzuke"
        #puts ps.size
        #puts ps.collect { |e| e.fei.to_s }.join("\n")

        assert_nil ps
    end

    def test_1

        $OWFE_LOG.level = Logger::DEBUG

        trace = []

        #@engine.register_participant :employee do
        #    trace << :assistant
        #end
        #@engine.register_participant :employee do
        #    trace << :employee
        #end
        [ :user_bob, :user_alice ].each do |p|
            @engine.register_participant p do
                trace << p
            end
        end

        @engine.reload

        ps = @engine.process_status "20080213-depejetzube" # an ruby procdef
        exp = ps.expressions.first
        wi = exp.applied_workitem

        @engine.reply wi

        sleep 0.400

        assert_equal [ :user_bob, :user_bob ], trace

        assert_nil @engine.process_status("20080213-depejetzube")
    end
end
