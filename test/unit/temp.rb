
%w[

  ut_0
  ut_1
  ut_2
  ut_3
  ut_4
  ut_5
  ut_6
  ut_7
  ut_8
  ut_9
  ut_10
  ut_11

  ut_13
  ut_14
  ut_15

  ut_17

].collect { |prefix|
  Dir[File.join(File.dirname(__FILE__), "#{prefix}_*.rb")].first
}.each { |file|
  require(file)
}

