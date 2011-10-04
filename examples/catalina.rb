
require 'rexml/document'
require 'pp'
require 'rubygems'
require 'ruote'

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))

class FetchData
  include Ruote::LocalParticipant

  def consume(workitem)

    workitem.fields['xml'] = %{
<?xml version='1.0?>
<car color="blue"><constructor name="nissan"/></car>
    }.strip

    reply_to_engine(workitem)
  end

  def cancel(fei, flavour)
    # nothing to do
  end
end

class ProcessData
  include Ruote::LocalParticipant

  def consume(workitem)

    xml = REXML::Document.new(workitem.fields['xml'])
    constructor = REXML::XPath.first(xml, '//constructor')
    workitem.fields['constructor'] = constructor.attribute('name').value

    pp workitem.fields

    reply_to_engine(workitem)
  end

  def cancel(fei, flavour)
    # nothing to do
  end
end

engine.register 'fetch_data', FetchData
engine.register 'process_data', ProcessData

pdef = Ruote.define do
  fetch_data
  process_data
end

engine.noisy = true

wfid = engine.launch(pdef)
r = engine.wait_for(wfid)

