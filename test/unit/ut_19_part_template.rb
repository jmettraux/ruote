
#
# testing ruote
#
# Thu Mar  4 10:24:30 JST 2010
#

require File.expand_path('../../test_helper', __FILE__)

require_json
require 'ruote/context'
require 'ruote/part/template'
require 'ruote/storage/hash_storage'


class UtPartTemplateTest < Test::Unit::TestCase

  class MyParticipant
    include ::Ruote::TemplateMixin

    def initialize

      @context = ::Ruote::Context.new(::Ruote::HashStorage.new)
    end
  end

  DEFAULT = %{
workitem for gonzalo

{
  "wfid": "20100304-bidehachina",
  "expid": "0_0_1"
}

 - 'car'  ==>  "BMW"
 - 'model'  ==>  "BMW 328 Mille Miglia"
  }.strip

  def setup

    @workitem = {
      'fei'=> { 'wfid' => '20100304-bidehachina', 'expid' => '0_0_1' },
      'participant_name' => 'gonzalo',
      'fields' => {
        'car' => 'BMW',
        'model' => 'BMW 328 Mille Miglia'
      }
    }
  end

  def test_default_template

    assert_equal(
      DEFAULT,
      MyParticipant.new.render_default_template(@workitem))

    assert_equal(
      DEFAULT,
      MyParticipant.new.render_template(nil, nil, @workitem))
  end

  def test_file_template

    fn = "#{__FILE__}.template"

    File.open(fn, 'wb') { |f| f.write('the model is ${f:model}') }

    assert_equal(
      'the model is BMW 328 Mille Miglia',
      MyParticipant.new.render_template(fn, nil, @workitem))

    FileUtils.rm_f(fn)
  end

  def test_string_template

    template = %{
My car is a ${f:car}
    }.strip

    assert_equal(
      'My car is a BMW',
      MyParticipant.new.render_template(template, nil, @workitem))
  end
end

