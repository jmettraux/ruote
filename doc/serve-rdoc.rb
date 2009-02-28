
require 'rubygems'
require 'rack'


$app = Rack::File.new('rdoc')

b = Rack::Builder.new do

  use Rack::CommonLogger
  use Rack::ShowExceptions
  run $app
end

port = 4567 # TODO : optparse me

puts ".. [#{Time.now}] rdoc is served on port #{port}"

Rack::Handler::Mongrel.run(b, :Port => port) do |server|
  trap(:INT) do
    puts ".. [#{Time.now}] stopped."
    server.stop
  end
end

