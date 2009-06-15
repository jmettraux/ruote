
#
# Testing Ruote
#
# Tue May 19 17:58:51 JST 2009
#


require File.dirname(__FILE__) + '/../test_helper.rb'

require 'ruote/pool/wfid_generator'


class UtWfidGenTest < Test::Unit::TestCase

  def test_last_file

    gen = Ruote::WfidGenerator.new
    gen.context = {}

    gen.generate

    assert File.read('work/wfidgen.last').size > 0
  end

  def test_uniqueness

    gen = Ruote::WfidGenerator.new
    gen.context = {}

    ids = []

    1_000.times { ids << gen.generate }

    assert_equal ids.size, ids.sort.uniq.size
  end
end

