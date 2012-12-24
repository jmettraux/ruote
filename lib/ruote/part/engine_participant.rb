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
# Made in Singapore.
#++

require 'ruote/util/subprocess'
require 'ruote/part/local_participant'


module Ruote

  #
  # A participant for pushing the execution of [segments of] processes to
  # other engines.
  #
  # It works by giving the participant the connection information to the storage
  # of the other engine.
  #
  # For instance :
  #
  #   engine0 =
  #     Ruote::Engine.new(
  #       Ruote::Worker.new(
  #         Ruote::FsStorage.new('work0', 'engine_id' => 'engine0')))
  #   engine1 =
  #     Ruote::Engine.new(
  #       Ruote::Worker.new(
  #         Ruote::FsStorage.new('work1', 'engine_id' => 'engine1')))
  #
  #   engine0.register_participant('engine1',
  #     Ruote::EngineParticipant,
  #     'storage_class' => Ruote::FsStorage,
  #     'storage_path' => 'ruote/storage/fs_storage',
  #     'storage_args' => 'work1')
  #   engine1.register_participant('engine0',
  #     Ruote::EngineParticipant,
  #     'storage_class' => Ruote::FsStorage,
  #     'storage_path' => 'ruote/storage/fs_storage',
  #     'storage_args' => 'work0')
  #
  # In this example, two engines are created (note that their 'engine_id' is
  # explicitely set (else it would default to 'engine')). Each engine is then
  # registered as participant in the other engine. The registration parameters
  # detail the class and the arguments to the storage of the target engine.
  #
  # This example is a bit dry / flat. A real world example would perhaps detail
  # a 'master' engine connected to 'departmental' engines, something more
  # hierarchical.
  #
  # The example also binds reciprocally engines. If the delegated processes
  # are always 'forgotten', one could imagine not binding the source engine
  # as a participant in the target engine (not need to answer back).
  #
  # There are then two variants for calling a subprocess
  #
  #   subprocess :ref => 'subprocess_name', :engine => 'engine1'
  #     # or
  #   participant :ref => 'engine1', :pdef => 'subprocess_name'
  #
  # It's OK to go for the shorter versions :
  #
  #   subprocess_name :engine => 'engine1'
  #     # or
  #   participant 'engine1', :pdef => 'subprocess_name'
  #   engine1 :pdef => 'subprocess_name'
  #
  # The subprocess is defined in the current process, or it's given via its
  # URL. The third variant is a subprocess bound as an engine variable.
  #
  #   engine.variables['variant_3'] = Ruote.process_definition do
  #     participant 'hello_world_3'
  #   end
  #
  #   pdef = Ruote.process_definition do
  #     sequence do
  #       engine1 :pdef => 'variant_1'
  #       engine1 :pdef => 'http://pdefs.example.com/variant_2.rb'
  #       engine1 :pdef => 'variant_3'
  #     end
  #     define 'variant_1' do
  #       participant 'hello_world_1'
  #     end
  #   end
  #
  class EngineParticipant

    include LocalParticipant

    def initialize(opts)

      if pa = opts['storage_path']
        require pa
      end

      kl = opts['storage_class']

      raise(ArgumentError.new("missing 'storage_class' parameter")) unless kl

      args = opts['storage_args']
      args = args.is_a?(Hash) ? [ args ] : Array(args)
      args << {} unless args.last.is_a?(Hash)
      args.last['preserve_configuration'] = true

      @storage = Ruote.constantize(kl).new(*args)
    end

    def consume(workitem)

      wi = workitem.to_h
      fexp = Ruote::Exp::FlowExpression.fetch(@context, wi['fei'])
      params = wi['fields'].delete('params')

      forget = (fexp.attribute(:forget).to_s == 'true')

      @storage.put_msg(
        'launch',
        'wfid' => wi['fei']['wfid'],
        'parent_id' => forget ? nil : wi['fei'],
        'tree' => determine_tree(fexp, params),
        'workitem' => wi,
        'variables' => fexp.compile_variables)

      fexp.unpersist if forget
        #
        # special behaviour here in case of :forget => true :
        # parent_id of remote expression is set to nil and local expression
        # is unpersisted immediately
    end

    def cancel(fei, flavour)

      exps = @storage.get_many('expressions', /^0![^!]+!#{fei.wfid}$/)

      return true if exps.size < 1
        # participant expression will reply to its parent

      @storage.put_msg(
        'cancel',
        'fei' => exps.first['fei'],
        'flavour' => flavour)

      false
        # participant expression will NOT reply to its parent
    end

    def reply(fei, workitem)

      @storage.put_msg(
        'reply',
        'fei' => fei,
        'workitem' => workitem)
    end

    protected

    def determine_tree(fexp, params)

      pdef = params['def'] || params['pdef'] || params['tree']

      tree = Ruote.lookup_subprocess(fexp, pdef)

      raise(
        "couldn't find process definition behind '#{pdef}'"
      ) unless tree

      tree.last
    end
  end
end

