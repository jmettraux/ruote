#!/usr/bin/env ruby

VERTICAL = %w[ ruby19 ruby ~/jruby-1.2.0/bin/jruby ]

args = ARGV.dup

RUBIES.each do |r|
  puts '=' * 80
  puts "#{r} #{args.join(' ')}"
  puts
  puts `#{r} #{args.join(' ')}`
  puts
end

