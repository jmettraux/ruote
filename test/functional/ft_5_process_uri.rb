
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Thu Feb 26 09:18:47 JST 2009
#

require File.dirname(__FILE__) + '/base'


class FtProcessUriTest < Test::Unit::TestCase
  include FunctionalBase

  def test_launch_missing_local_process

    assert_raise (Errno::ENOENT) {
      @engine.launch('tmp/missing.xml')
    }
  end

  def test_launch_missing_remote_process

    @engine.ac[:remote_definitions_allowed] = true

    assert_raise (Errno::ECONNREFUSED) {
      @engine.launch('http://127.0.0.1:56343/missing.xml')
    }
  end

  def test_launch_remote_process_when_forbidden

    @engine.ac[:remote_definitions_allowed] = false
      # making sure it's set to false

    assert_raise (RuntimeError) {
      @engine.launch('http://example.com/pdef0.rb')
    }
  end

  def test_launch_fs_stored_process

    prepare_def0

    @engine.launch('tmp/def0.xml')
  end

  protected

  def prepare_def0

    FileUtils.mkdir('tmp') rescue nil

    File.open('tmp/def0.xml', 'w') do |f|
      f.write(%{
<process-definition name="test">
  <echo>a</echo>
</process-definition>
      })
    end
  end

end

