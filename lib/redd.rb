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
      FileUtils.mkdir_p File.dirname(File.join(path, 'add', dest))
      file = FileUtils.cp src, File.join(path, 'add', dest), options
      File.new File.join(path, 'add', dest)
    end

    def remove list, options = {}
      list = [list] if list.instance_of? String
      File.open(File.join(path, 'delete.txt'), 'w') do |f|
        f.write list.join("\n")
      end
    end
  end
end
