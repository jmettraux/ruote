
#
# a method for checking the number of pending jobs left in the engine
#

module PendingJobsMixin

  def assert_no_jobs_left

    #cname = @engine.class.name
    #min_jobs = if cname == 'OpenWFE::CachedFilePersistedEngine'
    #  1
    #elsif cname == 'OpenWFE::Extras::CachedDbPersistedEngine'
    #  1
    #else
    #  0
    #end
    #assert_equal min_jobs, @engine.get_scheduler.pending_job_count

    assert_equal 0, @engine.get_scheduler.at_job_count
  end
end

