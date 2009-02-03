#!/usr/bin/env ruby

if ARGV.size < 1 or ARGV.include?('--help') or ARGV.include?('-h')
  puts %{

This test helper will run a given functional test with all the storage
implementations. It will exit as sooon as one of them fails.

It can run all the functional tests :

  ./mtest.rb --all

Or only one of them

  ./mtest.rb test/functional/ft_1_process_status.rb

  }
  exit 1
end

ARGV = [ 'test/functional/test.rb' ] \
  if ARGV.include?('--all') or ARGV.include?('-a')

ruby = `which ruby`.strip

[
  '', '--fs', '--tc',
  '--cfp',
  '--fs -y', '--fs -C', '--fs -C -y', '--tc -C'
].each do |args|

  puts
  puts '=' * 80
  puts "#{ruby} #{ARGV.join(' ')} -- #{args}"
  puts '=' * 80
  puts

  t = Time.now.to_f
  puts `#{ruby} #{ARGV.join(' ')} -- #{args}`
  d = Time.now.to_f - t

  break if $? != 0
end

