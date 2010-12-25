
#
# testing ruote
#
# Wed Oct 13 21:22:41 JST 2010
#

require File.join(File.dirname(__FILE__), 'base')

require 'ruote/participant'


class EftRegisterpTest < Test::Unit::TestCase
  include FunctionalBase

  def test_register_forbidden

    pdef = Ruote.define do
      registerp 'alpha', :class => 'C', :opt0 => 'val0'
    end

    wfid = @engine.launch(pdef)

    @engine.wait_for(wfid)

    err = @engine.errors.first

    assert_equal(
      "#<ArgumentError: 'registerp_allowed' is set to false, " +
      "cannot [un]register participants from process definitions>",
      err.message)
  end

  def test_register_from_attributes

    #@engine.noisy = true

    @engine.context['registerp_allowed'] = true

    pdef = Ruote.define do
      registerp 'alpha', :class => 'C', :opt0 => 'val_a'
      registerp /bravo/, :class => 'C', :opt0 => 'val_b'
      registerp :regex => /charly/, :class => 'C', :opt0 => 'val_c'
      registerp :regex => 'delta', :class => 'C', :opt0 => 'val_d'
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal(
      [
        [ '^alpha$', [ 'C', { 'opt0' => 'val_a' } ] ],
        [ 'bravo', [ 'C', { 'opt0' => 'val_b' } ] ],
        [ 'charly', [ 'C', { 'opt0' => 'val_c' } ] ],
        [ 'delta', [ 'C', { 'opt0' => 'val_d' } ] ]
      ],
      @engine.participant_list.collect { |e| e.to_a })
  end

  def test_register_from_workitem

    #@engine.noisy = true

    @engine.context['registerp_allowed'] = true

    pdef = Ruote.define do
      registerp :participants => 'participants'
      registerp :participant => 'participant'
    end

    wfid = @engine.launch(pdef,
      'participants' => [
        [ 'alpha', 'C', { 'opt0' => 'val_a' } ],
        [ '/bravo/', 'C', { 'opt0' => 'val_b' } ]
      ],
      'participant' => [ '/charly/', 'C', { 'opt0' => 'val_c' } ])

    @engine.wait_for(wfid)

    assert_equal(
      [
        [ '^alpha$', [ 'C', { 'opt0' => 'val_a' } ] ],
        [ 'bravo', [ 'C', { 'opt0' => 'val_b' } ] ],
        [ 'charly', [ 'C', { 'opt0' => 'val_c' } ] ]
      ],
      @engine.participant_list.collect { |e| e.to_a })
  end

  def test_register_with_position

    #@engine.noisy = true

    @engine.context['registerp_allowed'] = true

    pdef = Ruote.define do
      registerp 'alpha', :class => 'C', :opt0 => 'val_a'
      registerp /bravo/, :class => 'C', :opt0 => 'val_b', :position => 0
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal(
      [
        [ 'bravo', [ 'C', { 'opt0' => 'val_b', 'position' => 0 } ] ],
        [ '^alpha$', [ 'C', { 'opt0' => 'val_a' } ] ]
      ],
      @engine.participant_list.collect { |e| e.to_a })
  end

  def test_unregister

    #@engine.noisy = true

    @engine.context['registerp_allowed'] = true

    pdef = Ruote.define do
      registerp 'alpha', :class => 'C', :opt0 => 'val_a'
      unregisterp 'alpha'
    end

    wfid = @engine.launch(pdef)
    @engine.wait_for(wfid)

    assert_equal(
      [],
      @engine.participant_list.collect { |e| e.to_a })
  end
end

