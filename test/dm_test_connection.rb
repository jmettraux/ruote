
#
# establishing the datamapper connection for all the tests
#

require 'rubygems'

require 'dm-core'

DataMapper.setup(:default, 'mysql://localhost/test')

