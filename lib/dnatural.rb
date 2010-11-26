module Dnatural
  VERSION = 'Dnatural/0.17'
  class Dir < ::Dir
    include Namaste::Mixin
    include LockIt::Mixin
    
    def self.mkdir path, integer=0777, args = {}
      super path, integer
      d = Dir.new path
      d.type = Dnatural::VERSION

      ::Dir.chdir(d.path)  do
        ::Dir.mkdir 'admin'
        ::Dir.mkdir 'consumer'
	::Dir.mkdir 'producer'
	::Dir.mkdir 'system'
      end

      d
    end

    def list
      glob('**/*')
    end

    def add src, dest, options = {}
      FileUtils.cp src, File.join(path, dest), options
    end

    def remove list, options = {}
      list = [list] if list.instance_of? String 
      FileUtils.rm list.map { |x| File.join(path, x) }, options
    end
  end
end
