
%w{ lib test }.each do |path|
  path = File.expand_path(File.dirname(__FILE__) + '/../../' + path)
  $:.unshift(path) unless $:.include?(path)
end

require 'extras/active_connection'

module ApTestBase

  protected

    def new_wi (participant_name, hash={})

      wi = OpenWFE::Extras::Workitem.new

      wi.fei = "fei_#{Time.now.to_f}"
      wi.wfid = 'wfid'
      wi.wf_name = 'wf_name'
      wi.wf_revision = 'wf_revision'
      wi.participant_name = participant_name

      hash.each do |k, v|
        wi.fields << OpenWFE::Extras::Field.new_field(k, v)
      end

      wi
    end
end

