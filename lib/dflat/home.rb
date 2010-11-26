require 'namaste'
require 'lockit'
require 'anvl'
require 'dnatural'

module Dflat
  class Home # < ::Dir
    include Namaste::Mixin
    include LockIt::Mixin

    DEFAULT_PROPERTIES = { :objectScheme => 'Dflat/0.19', 
                           :manifestScheme => 'Checkm/0.1',
			   :fullScheme => 'Dnatural/0.19',
			   :deltaScheme => 'Dnatural/0.19',
                           :currentScheme => 'file',
			   :classScheme => 'CLOP/0.3' }

    def self.mkdir path, integer=0777, args = {}
      Dir.mkdir path, integer
      d = Home.new path
      d.type = Dflat::VERSION
      d.version! 'v001', nil
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

    def current
      v = current_version
      return nil unless v
      version(v)
    end

    def version version
      # xxx use namaste 'type' to load the right dir..
      Dnatural::Dir.new File.join(path, version)
    end

    def version! dest = nil, src = nil
      lock
      dest ||= next_version
      if src
        FileUtils.cp_r File.join(path, src), File.join(path, dest)
      else
	if current_version
          FileUtils.cp_r current.path, File.join(path, dest)
	else
          new_version(dest)
	end
      end

      self.current = dest
      unlock
      return version(dest)
    end

    def current= version
      return false unless File.directory? File.join(path, version)
      File.open(File.join(path, 'current.txt'), 'w') { |f| f.write(version) }
      @current = version
    end

    def versions
      ::Dir.glob(File.join(path, 'v*')).map
    end

    def select &block
      d = Dir.new path
      d.select &block
    end
    private
    def new_version version
      d = Dnatural::Dir.mkdir File.join(path, version)
    end

    def current_version
      @current ||= open(File.join(path, 'current.txt')).read.strip rescue nil
    end

    def next_version
      "v%03d" % (self.versions.map { |x| File.basename(x).sub(/^v/, '').to_i }.max + 1)
    end
  end
end
