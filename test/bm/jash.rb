
$:.unshift('lib')

require 'rubygems'

puts
#require 'json'; puts 'json'
require 'yajl/json_gem'; puts 'yjal'

require 'yaml'
require 'ruote/engine'
require 'ruote/util/jash'

yamled = %{--- !ruby/object:Ruote::Exp::SequenceExpression
applied_workitem: !ruby/object:Ruote::Workitem
  fei: !ruby/object:Ruote::FlowExpressionId
    engine_id: engine
    expid: 0_0_0
    wfid: 20090826-berutodiko
  fields: {}

children: []

created_time: 2009-08-26 19:04:28.545854 +09:00
fei: !ruby/object:Ruote::FlowExpressionId
  engine_id: engine
  expid: 0_0
  wfid: 20090826-berutodiko
modified_time: 2009-08-26 19:04:28.550609 +09:00
on_cancel:
on_error:
on_timeout:
original_tree:
- sequence
- {}

- - - echo
    - a:
    - []

  - - echo
    - b:
    - []

parent_id: !ruby/object:Ruote::FlowExpressionId
  engine_id: engine
  expid: "0"
  wfid: 20090826-berutodiko
state: failed
tagname:
updated_tree:
variables:
}

exp = YAML.load(yamled)
jashed = Ruote::Jash.encode(exp)
marshalled = Marshal.dump(exp)
jjashed = jashed.to_json

#puts yamled
#puts "=" * 80
#puts jjashed

puts
puts "marshalled.length      : #{marshalled.length}"
puts "jashed.to_json.length  : #{jjashed.length}"
puts "yamled.length          : #{YAML.dump(exp).length}"


require 'benchmark'

N = 5000

Benchmark.benchmark(' ' * 31 + Benchmark::Tms::CAPTION, 31) do |b|

  b.report('marshal dump') do
    N.times { Marshal.dump(exp) }
  end
  b.report('marshal load') do
    N.times { Marshal.load(marshalled) }
  end
  b.report('jash dump') do
    N.times { Ruote::Jash.encode(exp) }
  end
  b.report('jash load') do
    N.times { Ruote::Jash.decode(jashed) }
  end
  b.report('jash dump / to_json') do
    N.times { Ruote::Jash.encode(exp).to_json }
  end
  if defined?(::Yajl)
    b.report('jash load from json') do
      N.times { Ruote::Jash.decode(Yajl::Parser.parse(jjashed)) }
    end
  else
    b.report('jash load from json') do
      N.times { Ruote::Jash.decode(JSON.parse(jjashed)) }
    end
  end
  b.report('yaml dump') do
    N.times { YAML.dump(exp) }
  end
  b.report('yaml load') do
    N.times { YAML.load(yamled) }
  end
end

