
#
# testing ruote
#
# Thu Dec 24 18:05:39 JST 2009
#

require File.join(File.dirname(__FILE__), 'base')


class FtAddServiceTest < Test::Unit::TestCase
  include FunctionalBase

  class MyService

    attr_reader :context, :options

    def initialize (context, options={})

      @context = context
      @options = options
    end
  end

  def test_as_path_class

    @engine.add_service('toto', 'ruote', 'FtAddServiceTest::MyService')

    assert_equal MyService, @engine.context.toto.class
  end

  def test_as_instance

    @engine.add_service('toto', MyService.new(nil))

    assert_equal MyService, @engine.context.toto.class
  end

  def test_as_path_class_options

    @engine.add_service(
      'toto', 'ruote', 'FtAddServiceTest::MyService', 'colour' => 'blue')

    assert_equal MyService, @engine.context.toto.class
    assert_equal 'blue', @engine.context.toto.options['colour']
  end

  def test_add_service_returns_service

    toto = @engine.add_service(
      'toto', 'ruote', 'FtAddServiceTest::MyService', 'colour' => 'blue')

    assert_equal MyService, toto.class
  end
end

