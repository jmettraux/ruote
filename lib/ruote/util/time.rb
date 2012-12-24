#--
# Copyright (c) 2005-2013, John Mettraux, jmettraux@gmail.com
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
#
# Made in Japan.
#++

require 'rufus/scheduler'


unless DateTime.instance_methods.include?(:to_time)
  #
  # Ruby 1.9.1 has it, but not 1.8.x, so adding it...
  #
  class DateTime
    def to_time
      new_offset(0).instance_eval {
        Time.utc(year, mon, mday, hour, min, sec + sec_fraction)
      }.getlocal
    end
  end
end


module Ruote

  # Produces the UTC string representation of a Time
  #
  # like "2009/11/23 11:11:50.947109 UTC"
  #
  def self.time_to_utc_s(t)

    "#{t.utc.strftime('%Y-%m-%d %H:%M:%S')}.#{sprintf('%06d', t.usec)} UTC"
  end

  # Returns a parseable representation of the UTC time now.
  #
  # like "2009/11/23 11:11:50.947109 UTC"
  #
  def self.now_to_utc_s

    time_to_utc_s(Time.now)
  end

  # Turns a date or a duration to a Time object pointing AT a point in time...
  #
  # (my prose is weak)
  #
  def self.s_to_at(s)

    at = if s.index(' ')
      #
      # date

      DateTime.parse(s)

    else
      #
      # duration

      Time.now.utc.to_f + Rufus.parse_time_string(s)
    end

    case at
      when DateTime then at.to_time.utc
      when Float then Time.at(at).utc
      else at
    end
  end

  # Waiting for a better implementation of it in rufus-scheduler 2.0.4
  #
  def self.cron_string?(s)

    ss = s.split(' ')

    return false if ss.size < 5 || ss.size > 6
    return false if s.match(/\d{4}/)

    true
  end
end

