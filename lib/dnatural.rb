require 'checkm'
require 'namaste'
require 'fileutils'
require 'lockit'

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

    def version
      File.basename(path)
    end

    def manifest
      data = ''
      data = open(File.join(path, 'manifest.txt')).read if File.exists? File.join(path, 'manifest.txt')
      @manifest ||= Checkm::Manifest.new data
    end

    def manifest!
      @manifest = nil
      manifest
    end

    def list
      glob('**/*')
    end

    def add src, dest, options = {}
      file = FileUtils.cp src, File.join(path, dest), options

      manifest!

      lock
      m = manifest.add dest, :base => path
      File.open(File.join(path, 'manifest.txt'), 'w') do |f|
        f.write(m.to_s)
      end

      unlock

      File.new File.join(path, dest)
    end

    def remove list, options = {}
      list = [list] if list.instance_of? String 
      FileUtils.rm list.map { |x| File.join(path, x) }, options

      m = manifest!
      lock

      list.each do |l|
        m = m.remove l
      end

      File.open(File.join(path, 'manifest.txt'), 'w') do |f|
        f.write(m.to_s)
      end

      unlock
    end

  end
end
