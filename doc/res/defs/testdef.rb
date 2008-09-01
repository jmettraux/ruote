
class TestDefinition0 < OpenWFE::ProcessDefinition
  def make
    sequence do
      _print "a"
      _print "b"
      _print "c"
    end
  end
end

