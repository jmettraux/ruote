
class TeaTesting03 < OpenWFE::ProcessDefinition
  description "TeaTestingTeam version 0.3"
  sequence do
    reception
    concurrence do
      ted
      tang
    end
    takeshi
    _cancel_process :if => "${f:takeshi_appreciation} == bad"
    planning
  end
end

