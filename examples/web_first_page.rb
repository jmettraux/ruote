
#
# This is not a runnable example, it's just a ruby source file that contains
# the samples found at
#
#   http://ruote.rubyforge.org/index.html
#
# NOTE : this example need some rework. The use of block participants will
# probably be avoided
#

require 'rubygems'
require 'ruote'

pdef = Ruote.process_definition :name => 'work' do
  cursor do
    concurrence do
      reviewer1
      reviewer2
    end
    editor
    rewind :if => '${not_ok}' # back to the reviewers if editor not happy
    publish # the document
  end
end

# engine

require 'ruote/storage/fs_storage'

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::FsStorage.new('work')))

# participants

engine.register_participant 'reviewer.+' do |workitem|
  puts "reviewing document #{workitem.fields['doc_url']}"
  print "approve ?"
  workitem.fields["#{workitem.participant_name}_reply"] = gets
end

engine.register_participant 'editor' do |workitem|
  puts "doc : #{workitem.fields['doc_url']}"
  puts "reviewers approval :"
  workitem.fields.entries.each do |k, v|
    puts "#{k} : #{v}" if k.match(/\_reply$/)
  end
  print "should we publish ?"
  workitem.fields['not_ok'] = (gets.strip == 'no')
end

engine.register_participant 'publish' do |workitem|
  PublicationService.post(workitem.fields['doc_url'])
end

wfid0 = engine.launch(pdef, 'doc_url' => 'http://en.wikipedia.org/wiki/File:Bundesbrief.jpg')
wfid1 = engine.launch(pdef, 'doc_url' => 'http://en.wikipedia.org/wiki/File:Constitution_Pg1of4_AC.jpg')

# querying

[ wfid0, wfid1 ].each do |wfid|
  ps = engine.process(wfid)
  puts "errors for #{wfid} ? #{ps.errors.size > 0}"
end

# cancelling a process instance

engine.cancel_process(wfid1)

