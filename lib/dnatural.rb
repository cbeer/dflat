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

    def manifest
      @manifest ||= Checkm::Manifest.new open(File.join(path, 'manifest.txt')).read 
    end

    def manifest!
      @manifest = nil
      manifest
    end

    def list
      glob('**/*')
    end

    def add src, dest, options = {}
      FileUtils.cp src, File.join(path, dest), options

      manifest!

      lock
      m = manifest.add dest, :base => path
      File.open(File.join(path, 'manifest.txt'), 'w') do |f|
        f.write(m.to_s)
      end

      unlock
    end

    def remove list, options = {}
      list = [list] if list.instance_of? String 
      FileUtils.rm list.map { |x| File.join(path, x) }, options

      m = manifest!
      lock

      list.each do |l|
        m = m.remove l, :base => path
      end

      File.open(File.join(path, 'manifest.txt'), 'w') do |f|
        f.write(m.to_s)
      end

      unlock
    end

  end
end
