
%w[

  ft_0
  ft_1
  ft_2
  ft_3
  ft_4
  ft_5
  ft_6
  ft_7
  ft_8
  ft_9

  eft_0
  eft_1
  eft_2
  eft_3
  eft_4
  eft_5
  eft_6
  eft_7
  eft_8
  eft_9
  eft_10
  eft_11

].collect { |prefix|
  Dir[File.join(File.dirname(__FILE__), "#{prefix}_*.rb")].first
}.each { |file|
  require(file)
}

