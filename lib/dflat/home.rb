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
      ::Dir.mkdir path, integer
      d = Home.new path
      d.type = Dflat::VERSION
      d.info = args[:info] || DEFAULT_PROPERTIES
      d.init
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

    def next
      v = next_version
      version(v) if File.exists? File.join(path, v)
    end

    def version version
      # xxx use namaste 'type' to load the right dir..
      Dflat::Version::Dir.load File.join(path, version)
    end

    def init
      new_version('v001')
      self.current = 'v001'
    end

    def checkout
      lock
      if current_version and not File.exists?  File.join(path, next_version)
	FileUtils.cp_r current.path, File.join(path, next_version)
      end
      unlock
      return version(next_version)
    end

    def commit args = {}
      lock
      v = self.current = version(next_version)
      unlock
      v
    end

    def commit!
      lock
      # xxx full -> redd?
      previous = current
      v = self.current = version(next_version)

      previous.to_delta(current)

      unlock
      v
    end

    def export version
      v = version(version)
      return v if v.instance_of? Dflat::Version::Full
    end

    def [] version
      export(version)
    end

    def current= version
      version = version.version if version.respond_to? :version
      return false unless File.directory? File.join(path, version)
      File.open(File.join(path, 'current.txt'), 'w') { |f| f.write(version) }

      @current = version
    end

    def versions
      ::Dir.glob(File.join(path, 'v*')).map
    end

    def select &block
      d = Dflat::Version::Dir.new path
      d.select &block
    end

    private
    def new_version version
      d = Dflat::Version::Full.mkdir File.join(path, version)
    end

    def current_version
      @current ||= open(File.join(path, 'current.txt')).read.strip rescue nil
    end

    def next_version
      "v%03d" % (current_version.sub(/^v/, '').to_i + 1)
    end

    def update_directory_delta from, to = current
     
    end
  end
end
