
#--
# Copyright (c) 2010, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++

# featured in
#   http://jmettraux.wordpress.com/2010/01/29/barley/


require 'rubygems'

#
# the users
#

USERS = {
  '_none_' => 'http://s.twimg.com/a/1264550348/images/default_profile_0_normal.png',
  'john' => 'http://www.gravatar.com/avatar/8d96626e52beb1ff90f57a8e189e1e6f',
  'kenneth' => 'http://www.gravatar.com/avatar/8e033d0007374b14f6c213ede64d470b',
  'torsten' => 'http://www.gravatar.com/avatar/3fa5d7edd1f21da184964146e062c8da',
  'postmodern' => 'http://a3.twimg.com/profile_images/261097869/postmodern_bigger.jpg',
  'amedeo' => 'http://a1.twimg.com/profile_images/99817242/me_bigger.png',
  'radlepunktde' => 'http://a1.twimg.com/profile_images/303265014/radlepunktde_bigger.jpg'
}


#
# the workflow engine
#

require 'ruote'
require 'ruote/part/storage_participant'
require 'ruote/storage/fs_storage'

ENGINE = Ruote::Engine.new(
  Ruote::Worker.new(Ruote::FsStorage.new('ruote_data')))


#
# the workflow participants
#

ENGINE.register_participant('trace') do |workitem|
  (workitem.fields['trace'] ||= []) << [
    Time.now.strftime('%Y-%m-%d %H:%M:%S'),
    workitem.fields['next'],
    workitem.fields['task'] ]
end

ENGINE.register_participant('.+', Ruote::StorageParticipant)

PART = Ruote::StorageParticipant.new(ENGINE)
  # a handy pointer into the workitems


#
# the (only) process definition
#

PDEF = Ruote.process_definition :name => 'barely' do
  cursor do
    trace
    participant '${f:next}'
    rewind :if => '${f:next}'
  end
end

#
# web resources (thanks to Sinatra)
#

require 'cgi'
require 'sinatra'
require 'haml'

#use_in_file_templates!  # sinatra 0.9.x
enable :inline_templates  # sinatra 1.0

def h (s)
  Rack::Utils.escape_html(s)
end

def sort (workitems)
  workitems.sort! do |wi0, wi1|
    (wi0.fields['last'] || '') <=> (wi1.fields['last'] || '')
  end
end

set :haml, { :format => :html5 }

get '/' do
  redirect '/work'
end

get '/work' do

  @workitems = PART.all
  sort(@workitems)

  haml :work
end

get '/work/:thing' do

  t = params[:thing]

  @workitems = if USERS[t]
    PART.by_participant(t)
  else
    PART.by_field('subject', t)
  end
  sort(@workitems)

  haml :work
end

post '/new' do

  if n = params['next']
    wfid = ENGINE.launch(
      PDEF,
      'next' => n,
      'subject' => params['subject'],
      'task' => params['task'],
      'last' => Ruote.now_to_utc_s)
  end

  sleep 0.5

  redirect '/work'
end

post '/work' do

  fei = params['fei']
  fei = Ruote::FlowExpressionId.from_id(fei, ENGINE.context.engine_id)

  workitem = PART[fei]
    # fetch workitem from storage

  if params['action'] == 'resume'
    workitem.fields['next'] = params['next']
    workitem.fields['task'] = params['task']
    workitem.fields['last'] = Ruote.now_to_utc_s
    PART.reply(workitem)
  else # params['action'] == 'terminate'
    workitem.fields.delete('next')
    PART.reply(workitem)
  end

  sleep 0.5

  redirect '/work'
end

__END__

@@work

%html
  %head
    %title barley

    %script( src='http://code.jquery.com/jquery-1.4.1.min.js' )

    %link( href='http://barley.s3.amazonaws.com/reset.css' type='text/css' rel='stylesheet' )
    %link( href='http://ruote.rubyforge.org/images/ruote.png' type='image/png' rel='icon' )

    %style
      :sass
        body
          font-family: "helvetica neue", helvetica
          font-size: 14pt
          margin-left: 20%
          margin-right: 20%
          margin-top: 20pt

          background: #C0DEED url('http://a3.twimg.com/a/1264550348/images/bg-clouds.png') repeat-x
        p
          margin-bottom: 5pt
        input[type='text']
          width: 100%
        img
          width: 38px
        a
          color: black
          text-decoration: none
        a:visited
          color: black
          text-decoration: none
        a:active
          color: black
          text-decoration: none
        #barley
          font-size: 350%
          font-weight: lighter
          color: white
          padding-left: 2pt
          padding-bottom: 7pt
        #buttons
          font-size: 90%
          color: white
          margin-bottom: 14pt
        #buttons a
          color: white
        #buttons a:visited
          color: white
        .workitem
          margin-bottom: 7pt
        .workitem > *
          float: left
        .workitem:after
          display: block
          clear: both
          visibility: hidden
          content: ''
        .wi_info
          margin-left: 3pt
        .wi_user
          font-weight: bold
        .wi_task
          opacity: 0.37
          cursor: pointer
        .wi_wfid
          font-size: 70%
          vertical-align: middle
          font-weight: lighter
        table
          width: 100%
        tr.buttons > td
          text-align: center
          padding-top: 4pt
        td
          vertical-align: middle
        td.constrained
          width: 1%
          padding-right: 1em
        td.label
          font-weight: lighter
        .trace
          opacity: 0.37
          margin-bottom: 4pt
          cursor: pointer
        .trace_detail
          padding-left: 2pt
          border-left: 2.5pt solid #8EC1DA
        .trace_step
          width: 100%
        .trace_step_time
          font-size: 70%
        .trace_step_user
          font-weight: bold
          opacity: 0.6
        .trace_step_task
          opacity: 0.37

  %body

    #barley
      %span{ :onclick => "document.location.href = '/work';", :style => 'cursor: pointer;' } barley

    #message
      #{@message}

    #buttons

      %a{ :href => '', :onclick => "$('#new_form').slideToggle(); $('#new_next').focus(); return false;" } new
      |
      %a{ :href => '/work' } all

    #new_form{ :style => 'display: none;' }
      %form{ :action => '/new', :method => 'POST' }
        %table
          %tr
            %td.constrained{ :rowspan => 2 }
              %select#new_next{ :name => 'next', :onchange => "this.options[selectedIndex].select();" }
                - USERS.keys.sort.each do |uname|
                  - uavatar = USERS[uname]
                  %option{ :id => "new_#{uname}" } #{uname}
                  :javascript
                    document.getElementById('new_#{uname}').select = function () {
                      $('#new_avatar').get(0).src = '#{uavatar}';
                      $('#new_subject').focus();
                    }
              :javascript
                $('#new_next').get(0).value = '_none_';
            %td.constrained{ :rowspan => 2 }
              %img#new_avatar{ :src => USERS['_none_'] }
            %td.constrained.label
              subject
            %td
              %input{ :id => 'new_subject', :type => 'text', :name => 'subject', :value => '' }
          %tr
            %td.constrained.label
              task
            %td
              %input{ :type => 'text', :name => 'task', :value => '' }
          %tr.buttons
            %td{ :colspan => 4 }
              %input{ :type => 'submit', :value => 'launch' }

    #work
      - @workitems.each do |workitem|

        - wid = "workitem#{workitem.fei.hash.to_s}"

        .workitem
          .wi_user_image
            %img{ :src => USERS[workitem.participant_name], :class => 'wi_user' }
          .wi_info
            .wi_first_line
              %span.wi_user
                %a{ :href => "/work/#{h workitem.participant_name}" } #{h workitem.participant_name}
              %span.wi_subject
                %a{ :href => "/work/#{CGI.escape(workitem.fields['subject'])}" } #{h workitem.fields['subject']}
              %span.wi_task{ :onclick => "$('##{wid}').slideToggle(); $('#next_#{wid}').focus();" }
                #{h workitem.fields['task']}
            .wi_second_line
              %span.wi_wfid
                #{workitem.fei.wfid}
                - t = Rufus.to_ruby_time(workitem.fields['last'])
                - ago = Rufus.to_duration_string(Time.now - t.to_time, :drop_seconds => true)
                - ago = (ago.strip == '') ? 'a few seconds' : ago
                (#{ago} ago)

        .workitem_form{ :style => 'display: none;', :id => wid }

          .trace{ :onclick => "$('#trace#{wid}').slideToggle();" }
            - names = workitem.fields['trace'].collect { |e| e[1] }
            #{names.join(' &#187; ')}

          .trace_detail{ :id => "trace#{wid}", :style => 'display: none;' }
            - workitem.fields['trace'].each do |time, user, task|
              - t = Rufus.to_ruby_time(time)
              - ago = Rufus.to_duration_string(Time.now - t.to_time, :drop_seconds => true)
              %p.trace_step
                %span.trace_step_time #{h time} (#{ago} ago)
                %span.trace_step_user #{h user}
                %span.trace_step_task #{h task}

          %form{ :action => '/work', :method => 'POST' }
            %input{ :type => 'hidden', :name => 'fei', :value => workitem.fei.to_storage_id }
            %table
              %tr
                %td.constrained{ :rowspan => 2 }
                  %select{ :id => "next_#{wid}", :name => 'next', :onchange => "this.options[selectedIndex].select();" }
                    - USERS.keys.sort.each do |uname|
                      - uavatar = USERS[uname]
                      %option{ :id => "#{uname}_#{wid}" } #{uname}
                      :javascript
                        document.getElementById('#{uname}_#{wid}').select = function () {
                          $('#avatar_#{wid}').get(0).src = '#{uavatar}';
                          $('#task_#{wid}').focus();
                        }
                  :javascript
                    $('#next_#{wid}').get(0).value = '#{workitem.participant_name}';
                %td.constrained{ :rowspan => 2 }
                  %img{ :src => USERS[workitem.participant_name], :id => "avatar_#{wid}" }
                %td.constrained.label
                  subject
                %td
                  #{h workitem.fields['subject']}
              %tr
                %td.constrained.label
                  task
                %td
                  %input{ :id => "task_#{wid}", :type => 'text', :name => 'task', :value => workitem.fields['task'] }
              %tr.buttons
                %td{ :colspan => 4 }
                  %input{ :type => 'submit', :name => 'action', :value => 'resume' }
                  or
                  %input{ :type => 'submit', :name => 'action', :value => 'terminate' }

