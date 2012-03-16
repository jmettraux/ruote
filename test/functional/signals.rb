
#
# testing ruote
#
# Sat Sep 20 23:40:10 JST 2008
#


# Hitting CTRL-C reveals the fancy dashboard log (if any) and the
# current backtrace.
#
trap 'INT' do

  if $_dashboard && ! (ARGV.include?('-N') || ENV['NOISY'])
    puts
    puts '-' * 80
    puts $_dashboard.context.logger.fancy_log
  end

  puts
  puts '-' * 80
  puts *caller
  puts '-' * 80

  exit 1

end #if RUBY_VERSION.match(/^1.9./)


# Didn't use it much, pops a console while tests are running.
#
trap 'USR1' do

  require 'irb'
  require 'irb/completion'

  IRB.setup(nil)
  ws = IRB::WorkSpace.new(binding)
  irb = IRB::Irb.new(ws)
  IRB::conf[:MAIN_CONTEXT] = irb.context
  irb.eval_input
end


# USR2 is used for CI timeouts. Tries to print a max of useful information
# and then exits.
#
trap 'USR2' do

  # for CI timeouts

  begin

    puts
    puts '-' * 80
    puts *$_engine.context.logger.fancy_log if $_engine

    puts
    puts '-' * 80
    if defined?(MiniTest)
      ObjectSpace.each_object(
        MiniTest::Unit
      ).first.instance_eval do
        self.status
        puts
        @report.each_with_index do |msg, i|
          @@out.puts "\n%3d) %s" % [i + 1, msg]
        end
      end
    elsif defined?(Test::Unit::UI::Console::TestRunner)
      ObjectSpace.each_object(
        Test::Unit::UI::Console::TestRunner
      ).first.instance_eval do
        finished(-1)
      end
    else
      puts "no test/unit or MiniTest"
    end

    puts '-' * 80
    puts "threads: #{Thread.list.size}"
    Thread.list.each do |t|
      puts '-' * 80
      if Thread.current.respond_to?(:backtrace) # only >= 1.9.2p290 it seems
        puts "thread backtrace:"
        puts *t.backtrace
      else
        t.exit unless t == Thread.main
      end
    end

    puts '-' * 80

  rescue Exception => e
    p e
    puts *e.backtrace
  end

  exit 1
end

puts "pid #{$$}"

