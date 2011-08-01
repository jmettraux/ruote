
$:.unshift('lib')

require 'rubygems'
require 'ruote' # sudo gem install ruote
require 'atom/feed' # sudo gem install atom-tools
require 'prawn' # sudo gem install prawn

#
# starting a transient engine (no need to make it persistent)

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new()))

#
# a process that fetches the latest pictures from flickr.com and submits
# them concurrently to three users for review

pdef = Ruote.process_definition :name => 'picture_acquisition' do

  get_pictures

  concurrence :merge_type => 'mix' do
    # pass the picture list to three users concurrently
    # make sure to let their choice appear in the final workitem
    # at the end of the concurrence

    user_alice
    user_bob
    user_charly
    user_doug
  end

  generate_result_pdf
end

#
# fetching the flickr.com pictures via Atom

engine.register_participant :get_pictures do |workitem|

  feed = Atom::Feed.new(
    "http://api.flickr.com/services/feeds/photos_public.gne"+
    "?tags=#{workitem.fields['tags'].join(',')}&format=atom")
  feed.update!

  workitem.fields['pictures'] = feed.entries.inject([]) do |a, entry|
    a << [
      entry.title.to_s,
      entry.authors.first.name,
      entry.links.last.href
    ]
  end
end

#
# the users (well, here, just randomly picking a picture)

engine.register_participant 'user_.*' do |workitem|

  workitem.fields[workitem.participant_name] =
    workitem.fields['pictures'][(rand * workitem.fields['pictures'].length).to_i]
end

#
# the final participant, generates an "out.pdf" file in the current dir

# This time we implement a participant class. The "block participants" we
# have used so are nice, but they are not allowed to use backquotes, so ...
#
class ResultGenerator
  include Ruote::LocalParticipant

  def consume(workitem)

    entries = workitem.fields.inject([]) do |a, (k, v)|
      a << [ k, v.last ] if k.match(/^user\_.+$/)
      a
    end

    entries.each_with_index do |entry, i|
      entry << "pic#{i}.jpg"
      `curl #{entry[1]} > #{entry[2]}`
      puts "..got #{entry[0]} / #{entry[2]}"
    end

    Prawn::Document.generate('out.pdf') do
      font 'Helvetica'
      entries.each do |entry|
        text entry[0]
        image entry[2], :width => 200
      end
    end
    puts ".generated out.pdf"

    entries.each_with_index do |entry, i|
      `rm  "pic#{i}.jpg"`
      puts "..removed pic#{i}.jpg"
    end

    reply_to_engine(workitem)
  end
end

engine.register_participant :generate_result_pdf, ResultGenerator

#
# launching the process, requesting pictures tagged 'cat' and 'fish'

initial_workitem_fields = { 'tags' => [ 'cat', 'fish' ] }

fei = engine.launch(pdef, initial_workitem_fields)

#
# workflow engines are asynchronous beasts, have to wait for them
# (here we wait for a particular process)

outcome = engine.wait_for(fei)
#p outcome

