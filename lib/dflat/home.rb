# require 'namaste'
# require 'lockit'
# require 'anvl'

module Dflat
  class Home # < ::Dir
    def self.mkdir path, integer=0777, args = {}
      d = Dir.mkdir path, integer
      # namaste tag it!
      d = Home.new path
      d.current! 'v000'
      d
    end

    attr_reader :path, :info
    def initialize path, args = {}
      @path = path
      @info = nil
    end

    def info
      # xxx parse it with anvl
      @info ||= open(File.join(path, 'dflat-info.txt')).read
    end

    def log
      
    end 

    def each v=nil, &block
      version(v || current).each &block
    end

    def current
      version current_str
    end

    def version version
      # xxx use namaste 'type' to load the right dir..
      Dir.new File.join(path, version)
    end

    def current= version
      return false unless File.directory? File.join(path, version)
      File.open(File.join(path, 'current.txt'), 'w') { |f| f.write(version) }
      version
    end

    def current! version, type=nil
      # xxx  use namaste 'type' to create the right structure
      d = Dir.mkdir File.join(path, version)
      self.current=version
      d
    end


    def versions
      ::Dir.glob(path, 'v*').map
    end
    private

    def current_str
      @current ||= open(File.join(path, 'current.txt')).read.strip
    end
  end
end
