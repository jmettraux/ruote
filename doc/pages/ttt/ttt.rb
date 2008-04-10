
TITLES = [
    [ "prologue", 
      "a few things to note before commencing" ],
    [ "initial", 
      "initial context and process diagram" ],
    [ "soft", 
      "preparing Rails and Densha for 'hosting' the business process" ],
    [ "definition", 
      "a first process definition" ],
    [ "users", 
      "identifying the participants (and the users) to the process" ],
    [ "run",
      "first run of the business process" ],
    [ "tim",
      "first set of changes" ]
]

def extract_index (filename)

    /\D*(\d+)\.(rb|thtml)/.match(filename)[1].to_i
end

def title (filename)
    TITLES[extract_index(filename)][0]
end

def description (filename)
    TITLES[extract_index(filename)][1]
end

def render_ttt_menu (filename)

    index = extract_index(filename)

    s = "<div class='ttt_menu'>"

    s << "<a title='previous page' href='p#{index-1}.html'>&lt;</a> " \
        if index > 0

    i = -1

    s << TITLES.collect { |title, description|

        i += 1
        if i == index
            title
        else
            "<a title='#{description}' href='p#{i}.html'>#{title}</a>"
        end
    }.join(" | ")

    s << " <a title='next page' href='p#{index+1}.html'>&gt;</a>" \
        if index < TITLES.size - 1

    s << '</div>'

    s
end

def render_next_page (filename)

    index = extract_index(filename)

    if index < TITLES.size - 1
        "<div>" +
        "<a title='next page' href='p#{index+1}.html'>&gt;</a>" +
        '</div>'
    else
        ""
    end
end

def render_questions

    link = "http://groups.google.com/group/openwferu-users"

    "<div class='ttt_questions'>" +
    "questions and comments : " +
    "<a title='OpenWFEru users mailing list' href='#{link}'>#{link}</a>" +
    "</div>"
end

def rails_documentation
    '<a href="http://rubyonrails.org/docs">Ruby on Rails documentation</a>'
end

def thumbnail (image_href, percent, align=nil)

    s =  "<a "
    s << "href='#{image_href}' "
    s << ">"
    s << "<img "
    s << "class='thumbnail' "
    s << "align='#{align.to_s}' " if align
    s << "src='#{image_href}' "
    s << "width='#{percent}%' "
    s << '/></a>'
    s
end

