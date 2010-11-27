require 'checkm'
require 'namaste'
require 'fileutils'

module ReDD
  VERSION = 'ReDD/0.1'
  class Dir < ::Dir
    include Namaste::Mixin
    
    def self.mkdir path, integer=0777, args = {}
      super path, integer
      d = Dir.new path
      d.type = Dnatural::VERSION

      ::Dir.chdir(d.path)  do
        ::Dir.mkdir 'add'
	FileUtils.touch 'delete.txt'
      end
      d
    end

    def list
      NoMethodError
    end

    def add src, dest, options = {}
      NoMethodError
    end

    def remove list, options = {}
      NoMethodError
    end
  end
end
