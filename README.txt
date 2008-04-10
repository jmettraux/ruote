= OpenWFEru, Standard Library Documentation

== Prerequisites

Ruby 1.8.5 or later, RubyGems 0.9.4 or later

== Installation

Installation can be handled by Ruby gems.  This will pull in any libraries
you will need to install

  gem install -y openwferu

== Overview

OpenWFEru is a Ruby port of the OpenWFE workflow engine 
(http://www.openwfe.org).  It is a complete rewrite in Ruby 
so does not need to use the Java-based engine from OpenWFE.

OpenWFEru was initially implemented in San Joaquin de Flores, Costa Rica. And then in Yokohama, Japan.

One project goal for OpenWFEru is compatibility with its
Java based cousin so workflows defined for the Java engine
should work with the Ruby implementation.  There are
some incompatibilities between each implementation.

TODO: Document implementation differences

== Example

These are mostly stolen from the unit tests

Creating an workflow engine instance

    require 'rubygems'
    require 'openwfe/def'
    require 'openwfe/workitem'
    require 'openwfe/engine/engine'
    
    #
    # instantiating an engine
    
    engine = OpenWFE::Engine.new
    
    #
    # adding some participants
    
    engine.register_participant :alice do |workitem|
        puts "alice got a workitem..."
        workitem.alice_comment = "this thing looks interesting"
    end
    
    engine.register_participant :bob do |workitem|
        puts "bob got a workitem..."
        workitem.bob_comment = "not for me, I prefer VB"
        workitem.bob_comment2 = "Bob rules"
    end
    
    engine.register_participant :summarize do |workitem|
        puts 
        puts "summary of process #{workitem.fei.workflow_instance_id}"
        workitem.attributes.each do |k, v|
            next unless k.match ".*_comment$"
            puts " - #{k} : '#{v}'"
        end
    end
    
    #
    # a process definition
    
    class TheProcessDefinition0 < OpenWFE::ProcessDefinition
        sequence do
            concurrence do
                participant :alice
                participant :bob
            end
            participant :summarize
        end
    end
    
    #
    # launching the process
    
    li = OpenWFE::LaunchItem.new(TheProcessDefinition0)
    
    li.initial_comment = "please give your impressions about http://ruby-lang.org"
    
    fei = engine.launch li
        #
        # 'fei' means FlowExpressionId, the fei returned here is the
        # identifier for the root expression of the newly launched process
    
    puts "started process '#{fei.workflow_instance_id}'"
    
    engine.wait_for fei
        #
        # blocks until the process terminates


== How to help

If you want to help hacking on openwferu you'll probably want the following
libraries: 
[rake] Handle builds, generating documentation, and running unit tests
[rubygems] Handles creation of the gems
[rote] A framework being used to help with managing the offline written docs
[redcloth] OpenWFEru uses textile-markup for its docs.  Redcloth provides an engine for it.
[tidy] General cleanup

It's best if you use gems to install these as the process can get rather
tedious by hand.

=== Prerequisites

=== Ruby Libraries Install

1. gem install -r rake
2. gem install -r rote redcloth 
3. gem install -r tidy    

== Documentation

The main project site lives at rubyforge at:
http://rubyforge.org/projects/openwferu
or
http://openwferu.rubyforge.org

The users mailing list is at : http://groups.google.com/group/openwferu-users

