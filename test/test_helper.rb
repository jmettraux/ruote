
#
# testing ruote
#
# since Mon Oct  9 22:19:44 JST 2006
#

require File.join(File.dirname(__FILE__), 'path_helper')

require 'pp'
require 'test/unit'
require 'rubygems'

# Fail fast, especially when testing
#
Thread.abort_on_exception = true

# A helper method
#
def require_json

  return if $json_lib_loaded

  begin
    require 'yajl'
    require 'yajl/version'
    puts "using yajl #{Yajl::VERSION}"
  rescue LoadError
    require 'json'
    puts "using json #{JSON::VERSION}"
  end
  $json_lib_loaded = true
end

