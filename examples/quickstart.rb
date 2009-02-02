
require 'rubygems'
require 'openwfe/engine' # sudo gem install ruote
require 'atom/feed' # sudo gem install atom-tools

#
# starting a transient engine (no need to make it persistent)


engine = OpenWFE::Engine.new(:definition_in_launchitem_allowed => true)

#
# a process that fetches the latest pictures from flickr.com and submits
# them concurrently to three users for review

class MyProcess < OpenWFE::ProcessDefinition

  sequence do

    get_pictures

    concurrence :merge_type => 'mix' do
      # pass the picture list to three users concurrently
      # make sure to let their choice appear in the final workitem
      # at the end of the concurrence

      user_alice
      user_bob
      user_charly
    end

    show_results
      # display the pictures chosen by the users
  end
end

#
# fetching the flickr.com pictures via Atom

engine.register_participant :get_pictures do |workitem|

  feed = Atom::Feed.new(
    "http://api.flickr.com/services/feeds/photos_public.gne"+
    "?tags=#{workitem.tags.join(',')}&format=atom")
  feed.update!
  workitem.pictures = feed.entries.inject([]) do |a, entry|
    a << [ entry.title, entry.authors.first.name, entry.links.first.href ]
  end
end

#
# the users (well, here, just randomly picking a picture)

engine.register_participant 'user-.*' do |workitem|

  workitem.fields[workitem.participant_name] =
    workitem.pictures[(rand * workitem.pictures.length).to_i]
end

#
# the final participant, it displays the user choices

engine.register_participant :show_results do |workitem|
  puts
  puts ' users selected those images : '
  puts
  workitem.attributes.each do |k, v|
    next unless k.match(/^user-.*$/)
    puts "- #{k} :: #{v.last}"
  end
  puts
end

#
# launching the process, requesting pictures tagged 'cat' and 'fish'

li = OpenWFE::LaunchItem.new(MyProcess)
li.tags = [ 'cat', 'fish' ]

fei = engine.launch(li)

#
# workflow engines are asynchronous beasts, have to wait for them
# (here we wait for a particular process)

engine.wait_for(fei)

