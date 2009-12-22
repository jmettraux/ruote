
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
  ft_10
  ft_11
  ft_12
  ft_13
  ft_14
  ft_15
  ft_16
  ft_17
  ft_18
  ft_19
  ft_20
  ft_21
  ft_22
  ft_23
  ft_24
  ft_25
  ft_26
  ft_27
  ft_28
  ft_29

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
  eft_12
  eft_13
  eft_14
  eft_15
  eft_16
  eft_17
  eft_18
  eft_19
  eft_20
  eft_21
  eft_22
  eft_23
  eft_24
  eft_25
  eft_26
  eft_27
  eft_28
  eft_29

].collect { |prefix|
  Dir[File.join(File.dirname(__FILE__), "#{prefix}_*.rb")].first
}.each { |file|
  require(file)
}

