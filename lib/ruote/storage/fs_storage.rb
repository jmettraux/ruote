#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
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

require 'yaml'

require 'ruote/engine/context'
require 'ruote/queue/subscriber'
require 'ruote/storage/base'


module Ruote

  class FsStorage

    include EngineContext
    include StorageBase
    include Subscriber

    def context= (c)

      @context = c

      @path = @context[:expstorage_path] || workdir + '/expool'
      @yaml = (@context[:persist_as_yaml] == true)

      subscribe(:expressions)
    end

    def find_expressions (query={})

      fnames = if wfid = query[:wfid]
        Dir[File.join(dir_for(wfid)), '*.ruote']
      else
        all_filenames
      end

      fnames.inject([]) do |a, fn|
        exp = load_fexp(fn)
        a << exp if exp_match?(exp, query)
        a
      end
    end

    def []= (fei, fexp)

      d, fn = filename_for(fei)
      FileUtils.mkdir_p(d) unless File.exist?(d)

      File.open(File.join(d, fn), 'wb') { |f| f.write(encode(fexp)) }
    end

    def [] (fei)

      load_fexp(filename_for(fei, true))
    end

    def delete (fei)

      FileUtils.rm_f(filename_for(fei, true))
    end

    def size

      all_filenames.size
    end

    protected

    def all_filenames

      Dir["#{@path}/**/*.ruote"].size
    end

    def dir_for (wfid)

      swfid = wfidgen.split(wfid)

      "#{@path}/#{swfid[-2]}/#{swfid[-1]}"
    end

    def filename_for (fei, join=false)

      r = [ dir_for(fei.wfid), "#{fei.wfid}__#{fei.expid}.ruote" ]

      join ? File.join(*r) : r
    end

    def encode (fexp)

      @yaml ? fexp.to_yaml : Marshal.dump(fexp)
    end

    def load_fexp (path)

      return nil unless File.exist?(path)

      fexp = File.open(path, 'rb') { |f|
        s = f.read
        s[0, 5] == '--- !' ? YAML.load(s) : Marshal.load(s)
      }
      fexp.context = @context if fexp

      fexp
    end
  end
end

