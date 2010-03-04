
pers = ARGV.find { |a| a.match(/^--/) } || ''
tnumber = ARGV.find { |a| a.match(/^\d+/) } || 2

i = 0

puts `ruby -v`

loop do

  t = Dir["test/functional/ct_#{tnumber}_*.rb"].first

  raise "didn't find test..." unless t

  s = `ruby #{t} #{pers}`

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

