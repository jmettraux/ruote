
#require 'open3'

TEST = ARGV[0]

STORAGES = %w[ fs dm couch redis beanstalk ].unshift(nil)

unless TEST
  puts %{

USAGE :

  ruby test/functional/vertical.rb path/to/test.rb

will run the given test with against all the storage implementations.

#{STORAGES}

  }
  exit 0
end

STORAGES.each do |storage|

  dashdash = `ruby -v`.match(/^ruby 1\.9\./) ? '' : '--'
  storage = storage.nil? ? '' : "--#{storage}"

  command = "ruby #{TEST} #{dashdash} #{storage}"
  puts('-' * 80)
  puts("[32m#{command}[0m")

  #Open3.popen3("#{command} 2>&1") do |_, stdout, _|
  #  loop do
  #    s = stdout.read(7)
  #    break unless s
  #    $stdout.print(s)
  #    $stdout.flush
  #  end
  #end
    # popen3 is nice, but it doesn't set $?

  puts `#{command} 2>&1`

  puts("\n[41mFAILED[0m\n\n") if $?.exitstatus.to_i != 0
end

