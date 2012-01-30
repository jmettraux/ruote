
$:.unshift File.expand_path('../../lib', __FILE__)

require 'ruote'


describe 'my freaking process' do

  before 'each' do

    @board = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

    @board.register '.+' do |workitem|
      pname = workitem.participant_name
      fail 'doom' if pname != 'charly' && workitem.fields['fail']
      workitem.fields[workitem.participant_name] = 'was here'
    end
  end

  after 'each' do

    @board.shutdown
  end

  let(:definition) do
    Ruote.define :on_error => 'charly' do
      alpha
      bravo
    end
  end

  # the specs...

  context 'happy path' do

    it 'completes successfully' do

      wfid = @board.launch(definition)

      r = @board.wait_for(wfid)
        # wait until process terminates or hits an error

      r['workitem'].should_not == nil
      r['workitem']['fields']['alpha'].should == 'was here'
      r['workitem']['fields']['bravo'].should == 'was here'
      r['workitem']['fields']['charly'].should == nil
    end
  end

  context 'unhappy path' do

    it 'routes to charly' do

      initial_workitem_fields = { 'fail' => true }

      wfid = @board.launch(definition, initial_workitem_fields)

      r = @board.wait_for(wfid)
        # wait until process terminates or hits an error

      r['workitem'].should_not == nil
      r['workitem']['fields']['alpha'].should == nil
      r['workitem']['fields']['bravo'].should == nil
      r['workitem']['fields']['charly'].should == 'was here'
    end
  end
end

