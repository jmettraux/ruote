
#
# testing ruote
#
# Fri Apr 15 09:49:10 JST 2011
#
# over Canada, between SFO and FRA
#


require File.expand_path('../base', __FILE__)

require_json
Rufus::Json.detect_backend


class EftReadTest < Test::Unit::TestCase
  include FunctionalBase

  def test_read_text_file

    dir = "t_rtf_#{$$}_#{self.object_id}_#{Time.now.to_f}"
    fname = File.join(dir, 'message.txt')
    FileUtils.mkdir(dir)

    File.open(fname, 'wb') { |f| f.write('kilroy was here') }

    pdef = Ruote.process_definition do
      read fname, :to => 'x'
      read :from => fname, :to => 'f:y'
      read fname, :to => 'v:z'
      set 'f:z' => '$v:z'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    fields = @dashboard.wait_for(wfid)['workitem']['fields']

    assert_equal(
      [ 'kilroy was here' ],
      %w[ x y z ].collect { |k| fields[k] }.uniq)

  ensure
    FileUtils.rm_rf(dir)
  end

  def test_read_json_file

    dir = "t_rjf_#{$$}_#{self.object_id}_#{Time.now.to_f}"
    fname = File.join(dir, 'message.json')
    FileUtils.mkdir(dir)

    File.open(fname, 'wb') do |f|
      f.puts(Rufus::Json.encode('kilroy' => 'here'))
    end

    pdef = Ruote.process_definition do
      read fname, :to => 'x'
      read :from => fname, :to => 'f:y'
      read fname, :to => 'v:z'
      set 'f:z' => '$v:z'
    end

    #@dashboard.noisy = true

    wfid = @dashboard.launch(pdef)

    fields = @dashboard.wait_for(wfid)['workitem']['fields']

    assert_equal(
      [ { 'kilroy' => 'here' } ],
      %w[ x y z ].collect { |k| fields[k] }.uniq)

  ensure
    FileUtils.rm_rf(dir)
  end

  def test_read_http

    pdef = Ruote.process_definition do
      read 'http://ruote.s3.amazonaws.com/eft_36_read.txt', :to => :x
      read 'http://ruote.s3.amazonaws.com/eft_36_read.json', :to => :y
    end

    wfid = @dashboard.launch(pdef)

    fields = @dashboard.wait_for(wfid)['workitem']['fields']

    assert_equal(
      "kilroy was here\n", fields['x'], "\nkilroy wasn't here (no network ?)\n")
    assert_equal(
      { 'kilroy' => 'here' }, fields['y'])
  end
end

