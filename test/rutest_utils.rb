#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'openwfe/version'


class Tracer

    def initialize
        super
        @trace = ""
    end

    def to_s
        @trace.to_s.strip
    end

    def << s
        @trace << s
    end

    def clear
        @trace = ""
    end

    def puts s
        @trace << "#{s}\n"
    end
end

#
# Returns a new FlowExpressionId, for testing purposes
#
def new_fei

    fei = OpenWFE::FlowExpressionId.new

    fei.owfe_version = OpenWFE::OPENWFERU_VERSION
    fei.engine_id = 'this'
    #fei.initial_engine_id = 'that'
    fei.workflow_definition_url = 'http://test/test.xml'
    fei.workflow_definition_name = 'test'
    fei.workflow_definition_revision = '1.0'
    fei.workflow_instance_id = '123456'
    fei.expression_name = 'do-test'
    fei.expression_id = '0.0'

    fei
end

#
# Returns true when on JRuby
#
def on_jruby?

    (defined?(JRUBY_VERSION) != nil)
end

