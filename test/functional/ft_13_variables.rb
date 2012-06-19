
#
# testing ruote
#
# Tue Jun 23 11:16:39 JST 2009
#

require File.expand_path('../base', __FILE__)


class FtVariablesTest < Test::Unit::TestCase
  include FunctionalBase

  def test_wfid_and_expid

    pdef = Ruote.process_definition do
      echo 'at:${wfid}:${expid}'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal "at:#{wfid}:0_0", @tracer.to_s
  end

  def test_mnemo_id

    pdef = Ruote.process_definition do
      echo '>${mnemo_id}<'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_match /^>[a-z]+<$/, @tracer.to_s
  end

  def test_tags

    pdef = Ruote.define do
      sequence :tag => 'a' do
        sequence :tag => 'b' do
          sequence :tag => 'c' do
            echo '>${tags}<'
            echo '>${tag}<'
            echo '>${full_tag}<'
          end
        end
      end
    end

    wfid = @dashboard.launch(pdef); r = @dashboard.wait_for(wfid)

    assert_equal 'terminated', r['action']
    assert_equal [ ">[\"a\", \"b\", \"c\"]<", ">c<", ">a/b/c<" ], @tracer.to_a
  end

  def test_variables_event

    pdef = Ruote.process_definition do
      sequence do
        set :var => 'v', :val => 'x'
        unset :var => 'v'
        echo 'done.'
      end
    end

    assert_trace('done.', pdef)

    #logger.log.each { |e| p e }

    assert_equal(
      1, logger.log.select { |e| e['action'] == 'variable_set' }.size)
    assert_equal(
      1, logger.log.select { |e| e['action'] == 'variable_unset' }.size)
  end

  def test_process_root_variables

    pdef = Ruote.process_definition do
      sequence do
        set 'v:va' => 'a0'
        set 'v:/vb' => 'b0'
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
        sub0
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
      end
      define 'sub0' do
        set 'v:va' => 'a1'
        set 'v:/vb' => 'b1'
        echo '${v:va}:${v:vb}:${v:/va}:${v:/vb}'
      end
    end

    assert_trace(%w[ a0:b0:a0:b0 a1:b1:a0:b1 a0:b1:a0:b1 ], pdef)
  end

  def test_engine_variables

    pdef = Ruote.process_definition do
      sequence do
        set 'v:va' => 'a0'
        echo '${v:va}:${v://va}'
        echo '${v:vb}:${v://vb}'
        echo 'done.'
      end
    end

    @dashboard.variables['vb'] = 'b0'

    assert_trace(%w[ a0: b0:b0 done. ], pdef)

    assert_equal(
      1, logger.log.select { |e| e['action'] == 'variable_set' }.size)
  end

  # A test about a protected method in FlowExpression, quite low level.
  #
  def test_lookup_var_site

    pdef = Ruote.process_definition do
      sequence do
        sub0
        echo 'done.'
      end
      define 'sub0' do
        alpha
      end
    end

    @dashboard.context.stash[:results] = []

    @dashboard.register_participant :alpha do |workitem, fexp|

      class << fexp
        public :locate_var
      end

      stash[:results] << fexp.locate_var('//a')
      stash[:results] << fexp.locate_var('/a').first.fei.to_storage_id
      stash[:results] << fexp.locate_var('a').first.fei.to_storage_id
    end

    assert_trace 'done.', pdef

    assert_equal(nil, @dashboard.context.stash[:results][0])
    assert_match(/^0||\d+_\d+$/, @dashboard.context.stash[:results][1])
    assert_match(/^0\_0|\d+|\d+_\d+$/, @dashboard.context.stash[:results][2])
  end

  def test_lookup_var

    pdef = Ruote.define do
      set 'v:v0' => 'a'
      sequence :scope => true do
        echo 'v0:${v:v0}'
        set 'v:v0' => nil
        echo 'v0:${v:v0}'
      end
      echo 'v0:${v:v0}'
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal %w[ v0:a v0: v0:a ], @tracer.to_a
  end

  def test_set_var_override

    pdef = Ruote.define do
      set 'v:v0' => 'a'
      sequence :scope => true do
        set 'v:v0' => 'b', :over => true
        set 'v:v1' => 'b', :over => true
        set 'v:/v2' => 'b', :over => true
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal(
      { 'v0' => 'b', 'v2' => 'b' },
      r['variables'])
  end

  def test_set_var_override_sub

    pdef = Ruote.define do

      set 'v:v0' => 'a'
      set 'v:v1' => 'a'
      set 'v:v2' => 'a'
      set 'v:v3' => 'a'
      sub0
      sequence :scope => true do
        set 'v:v4' => 'a', :over => 'sub'
      end

      define 'sub0' do
        set 'v:v0' => 'b'
        set 'v:v1' => 'b', :over => true
        set 'v:v3' => 'b'
        sequence :scope => true do
          set 'v:v2' => 'c', :over => 'sub'
          set 'v:v3' => 'c', :over => 'sub'
        end
        set 'v:/v3' => '${v:v3}'
      end
    end

    wfid = @dashboard.launch(pdef)
    r = @dashboard.wait_for(wfid)

    assert_equal(
      [ 'a', 'b', 'a', 'c', nil ],
      r['variables'].values_at(*%w[ v0 v1 v2 v3 v4 ]))
  end

  def test_lookup_in_var

    @dashboard.register_participant :echo_toto do |wi, fexp|
      tracer << fexp.lookup_variable('toto').join + "\n"
    end

    pdef = Ruote.process_definition do

      set 'v:toto' => %w[ a b c ]
      echo '${v:toto.1}'

      set 'v:toto.2' => 'C'
      echo_toto

      unset 'v:toto.1'
      echo_toto
    end

    assert_trace(%w[ b abC aC ], pdef)
  end

  def test_terminated_and_variables

    pdef = Ruote.define {}

    wfid = @engine.launch(pdef, {}, { 'a' => 'b' })
    r = @engine.wait_for(wfid)

    assert_equal({ 'a' => 'b' }, r['variables'])
  end
end

