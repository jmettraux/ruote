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


class Ruote::WaitLogger

  # fancy msg logic

  protected

  #--
  # <ESC>[{attr1};...;{attrn}m
  #
  # 0 Reset all attributes
  # 1 Bright
  # 2 Dim
  # 4 Underscore
  # 5 Blink
  # 7 Reverse
  # 8 Hidden
  #
  # Foreground Colours
  # 30 Black
  # 31 Red
  # 32 Green
  # 33 Yellow
  # 34 Blue
  # 35 Magenta
  # 36 Cyan
  # 37 White
  #
  # Background Colours
  # 40 Black
  # 41 Red
  # 42 Green
  # 43 Yellow
  # 44 Blue
  # 45 Magenta
  # 46 Cyan
  # 47 White
  #++

  def color(mod, s, clear=false)

    return s if Ruote::WIN
    return s unless STDOUT.tty?

    "[#{mod}m#{s}[0m#{clear ? '' : "[#{@color}m"}"
  end

  def fei_to_s(fei, wfid)
    [
      fei['expid'],
      fei['subid'][0, 5] + '...',
      fei['wfid'] != wfid ? fei['wfid'] : ''
    ].join('!')
  end

  def radial_tree(msg)

    _, t = Ruote::Exp::DefineExpression.reorganize(msg['tree'])

    Ruote::Reader.to_expid_radial(t).split("\n").inject('') do |s, l|
      m = l.match(/^(\s*[0-9_]+)(.+)$/)
      s << "\n  "
      s << color(33, m[1])
      s << color(32, m[2])
      s
    end
  end

  def fancy_print(msg, noisy=true)

    @count = (@count + 1) % 10

    wo = Ruote.current_worker
    woi = [ wo.object_id.to_s[-2..-1] ]
    if wo.class != Ruote::Worker || wo.name != 'worker'
      woi << wo.class.name.split('::').last[0, 2]
      woi << wo.name[0, 2]
    end
    woi = woi.join(':')

    fei = msg['fei']
    depth = fei ? fei['expid'].split('_').size : 0

    i = fei ?
      [ fei['wfid'], (fei['subid'] || '')[0, 5], fei['expid'] ].join(' ') :
      msg['wfid']
    wfid = fei ? fei['wfid'] : msg['wfid']

    rest = msg.dup
    %w[
      _id put_at _rev
      type action
      fei wfid variables
    ].each { |k| rest.delete(k) }

    if v = rest['parent_id']
      rest['parent_id'] = fei_to_s(v, wfid)
    end
    if v = rest.delete('workitem')
      rest[:wi] = [
        v['fei'] ? fei_to_s(v['fei'], wfid) : nil,
        v['fields'].size ]
    end
    if v = rest.delete('supplanted')
      rest[:supplanted] = '...'
    end

    #if t = rest.delete('tree')
    #  rest[:t] = color(37, t.inspect, true)
    #end

    { 'tree' => :t, 'parent_id' => :pi }.each do |k0, k1|
      if v = rest.delete(k0)
        rest[k1] = v
      end
    end

    #rest.delete(:t) if fei.nil? && msg['action'] == 'launch'
      #
      # don't do that since the radial display is reorganized and this
      # tree is not.

    if v = rest.delete('participant')
      rest['part'] = v.first == 'Ruote::BlockParticipant' ? v.first : v
    end

    act = msg['action'][0, 2]
    act = case msg['action']
      when 'receive' then 'rc'
      when 'dispatched' then 'dd'
      when 'dispatch_cancel' then 'dc'
      when 'dispatch_pause' then 'dp'
      when 'dispatch_resume' then 'dr'
      when 'pause', 'pause_process' then 'pz'
      when 'resume', 'resume_process' then 'rz'
      when 'regenerate' then 'rg'
      when 'reput' then 'rp'
      when 'respark' then 'sk'
      else act
    end
    act = case act
      when 'la', 'rg', 'sk' then color('4;32', act)
      when 'te' then color('4;31', act)
      when 'ce' then color('31', act)
      when 'ca' then color('31', act)
      when 'dc' then color('4;31', act)
      when 'pz' then color('4;31', act)
      when 'rz' then color('4;32', act)
      when 'dp' then color('4;31', act)
      when 'dr' then color('4;32', act)
      when 'rp' then color('32', act)
      when 'er', 'ra' then color('31', act)
      when 'di', 'dd', 'rc' then color('4;33', act)
      else act
    end
    unless ACTIONS.include?(msg['action'])
      rest['action'] = msg['action']
      act = color('36', msg['action'][0, 2])
    end

    tm = Time.now
    tm = tm.strftime('%M:%S.') + ('%03d' % ((tm.to_f % 1.0) * 1000.0).to_i)
    tm = color(37, tm, false)

    s = if %w[ error_intercepted raise ].include?(msg['action'])
      #
      # display backtraces

      rst = Ruote.insp(
        rest.reject { |k, v| %w[ error msg ].include?(k) },
        :trim => %[ updated_tree ])[1..-2]

      tail = []
      tail << "  #{wfid} * class:  #{rest['error']['class']}"
      tail << "  #{wfid} * msg:    #{rest['error']['message']}"

      trace = rest['error']['trace']
      trace = trace[0, 2] + [ '...' ] if msg['action'] == 'raise'

      trace.each { |line| tail << "  #{wfid} #{line}" }

      color(
        @color,
        "#{@count} #{tm} #{woi} #{'  ' * depth}#{act} * #{i} #{rst}",
        true
      ) +
      "\n" +
      color(
        @color,
        tail.join("\n"),
        true)

    else
      #
      # regular "lines"

      pa = if %w[ receive dispatch dispatch_cancel ].include?(msg['action'])
        color('34', rest.delete('participant_name')) + ' '
      else
        ''
      end

      rest = Ruote.insp(rest, :trim => %[ updated_tree ])[1..-2]

      color(
        @color,
        "#{@count} #{tm} #{woi} #{'  ' * depth}#{act} * #{i} #{pa}#{rest}",
        true)
    end

    s << radial_tree(msg) if fei.nil? && msg['action'] == 'launch'

    s

  rescue => e
    "* fancy_print fail\n" +
    "** msg: #{msg.inspect}\n" +
    "** err: #{e.to_s} / #{e.backtrace.first}"
  end
end

