require 'namaste'
# require 'lockit'
require 'anvl'

module Dflat
  class Home # < ::Dir
    DEFAULT_PROPERTIES = { :objectScheme => 'Dflat/0.19', 
                           :manifestScheme => 'Checkm/0.1',
			   :fullScheme => 'Dnatural/0.19',
			   :deltaScheme => 'Dnatural/0.19',
                           :currentScheme => 'file',
			   :classScheme => 'CLOP/0.3' }

    def self.mkdir path, integer=0777, args = {}
      Dir.mkdir path, integer
      d = Dir.new path
      d.type = Dflat::VERSION
      d = Home.new path
      d.current! 'v001'
      d.info = args[:info] || DEFAULT_PROPERTIES
      d
    end

    attr_reader :path
    def initialize path, args = {}
      @path = path
      @info = nil
    end

    def info
      # xxx parse it with anvl
      return @info if @info
      return @info = {} unless File.exists? File.join(path, 'dflat-info.txt')

      anvl = open(File.join(path, 'dflat-info.txt')).read
      @info = ANVL.parse anvl
    end

    def info=(properties = @info)
      File.open(File.join(path, 'dflat-info.txt'), 'w') { |f| f.write(ANVL.to_anvl(properties)) }
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
