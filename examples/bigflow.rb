#
# just a sample
#

class BigFlow0 < OpenWFE::ProcessDefinition

  sequence do
    alpha
    concurrence do
      bravo
      cursor do
        alpha
        bravo
      end
      alpha :activity => "brush teeth"
    end
    bravo
  end
end
