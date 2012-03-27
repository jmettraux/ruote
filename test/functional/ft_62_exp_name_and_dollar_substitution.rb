
#
# testing ruote
#
# Sat Jun 25 21:00:57 JST 2011
#

require File.expand_path('../base', __FILE__)


class FtExpNameAndDollarSubstitution < Test::Unit::TestCase
  include FunctionalBase

  def test_t_fields

    pdef = <<-EOS
define
  set 'v:x': alpha
  user_${v:x}
  user_${v:nada}
    EOS

    @dashboard.register /^user_/ do |wi|
      tracer << wi.participant_name + "\n"
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)
    @dashboard.wait_for(wfid)

    assert_equal %w[ user_alpha user_ ], @tracer.to_a
  end
end

