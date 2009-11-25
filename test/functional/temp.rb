
%w[
  eft_0
  eft_1
  eft_2
  eft_3
  eft_4
  eft_5
  eft_6
].collect { |prefix|
  Dir[File.join(File.dirname(__FILE__), "#{prefix}_*.rb")].first
}.each { |file|
  require(file)
}

