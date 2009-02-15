
#
# testing Ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require File.dirname(__FILE__) + '/path_helper'

require 'test/unit'
require 'rubygems'

#
# Returns a new FlowExpressionId, for testing purposes
#
def new_fei (wfid='20080919-equestris')

  fei = OpenWFE::FlowExpressionId.new

  fei.owfe_version = OpenWFE::OPENWFERU_VERSION
  fei.engine_id = 'this'
  #fei.initial_engine_id = 'that'
  fei.workflow_definition_url = 'http://test/test.xml'
  fei.workflow_definition_name = 'test'
  fei.workflow_definition_revision = '1.0'
  fei.workflow_instance_id = wfid
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

