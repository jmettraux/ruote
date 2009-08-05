
#
# Testing Ruote
#
# Tue May 19 17:58:51 JST 2009
#

require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

require 'ruote/pool/wfid_generator'
require 'ruote/pool/mnemo_wfid_generator'


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

  def test_split

    gen = Ruote::WfidGenerator.new
    gen.context = {}

    assert_equal(
      [
        "2", "0", "0", "9", "0", "7", "2", "2", "1", "7", "5", "7", "4", "0",
        "-", "5", "1", "5", "2", "4", "3"
      ],
      gen.split('20090722175740-515243'))
  end

  def test_mnemo_uniqueness

    gen = Ruote::MnemoWfidGenerator.new
    gen.context = {}

    ids = []

    1_000.times { ids << gen.generate }

    #p ids.sort.uniq

    assert_equal ids.size, ids.sort.uniq.size
  end

  def test_mnemo_split

    gen = Ruote::MnemoWfidGenerator.new
    gen.context = {}

    assert_equal(
      ["bo", "ji", "pe", "pu", "he"], gen.split('20090722-bojipepuhe'))
  end
end

