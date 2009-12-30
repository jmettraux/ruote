
pers = ARGV.find { |a| a.match(/^--/) } || ''

i = 0

loop do

  #s = `ruby test/functional/ct_0_concurrence.rb #{pers}`
  #s = `ruby test/functional/ct_1_iterator.rb #{pers}`
  s = `ruby test/functional/ct_2_cancel.rb #{pers}`

  if $? != 0
    puts
    puts s
  else
    if (i % 5) == 0
      print i.to_s
    else
      print '.'
    end
    STDOUT.flush
  end

  i = i + 1
end

