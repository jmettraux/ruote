
#
# Testing Ruote (OpenWFEru)
#
# John Mettraux at openwfe.org
#
# Wed Feb  4 10:16:34 JST 2009
#

require 'openwfe/engine'

$in_memory_engine = false

module RestartBase

  def in_memory_engine

    return true if $in_memory_engine
    return false unless @engine.class == OpenWFE::Engine

    $in_memory_engine = true

    puts
    puts "  skipping restart (rft_) tests : in-memory engine"
    puts

    true
  end

  def restart_engine

    ac = {
      '__tracer' => @tracer,
      :persist_as_yaml => @engine.ac[:persist_as_yaml],
      :no_expstorage_cache => @engine.ac[:no_expstorage_cache]
    }

    @engine = @engine.class.new(ac)

    @engine.reload # very important
  end
end

