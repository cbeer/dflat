module Dflat
  class Dir < ::Dir
    def each &block
      return Dir.new(File.join(path, 'full')).each &block if File.directory? File.join(path, 'full')
    end
  end
end
