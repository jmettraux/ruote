#
# Testing OpenWFE
#
# John Mettraux at openwfe.org
#
# Mon Oct  9 22:19:44 JST 2006
#

require 'rubygems'

#
# the tests that take lots of time...
#

require 'ft_5_time'

require 'restart_tests'

#require 'ft_20_cron'
#require 'ft_21_cron'
#require 'ft_21b_cron_pause'
require 'cron_ltest'

require 'ft_67_schedlaunch'

require 'ft_51_stack'

require 'ft_29_httprb' # needs net connection

#require 'ft_30_socketlistener'
    #
    # shaky test...

#
# the quick tests
#
#require 'rake_qtest'

