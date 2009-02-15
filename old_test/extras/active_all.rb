
#
# all the "Active" tests
#

%w{ lib test }.each do |path|
  path = File.expand_path(File.dirname(__FILE__) + '/../../' + path)
  $:.unshift(path) unless $:.include?(path)
end

require 'extras/ap_0_test'
require 'extras/ap_1_test'
require 'extras/active_with_engine_test'
require 'extras/db_expstorage_utest'
require 'extras/db_errorjournal_utest'
require 'extras/db_history_0_test'

