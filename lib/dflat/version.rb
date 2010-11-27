require 'namaste'
require 'lockit'
require 'fileutils'
module Dflat
  module Version
    class Dir < ::Dir
      include Namaste::Mixin
      include LockIt::Mixin
     
      def self.load path
        Full.new path
      end

      def version
        File.basename(path)
      end
      def manifest
        data = ''
        data = open(manifest_path).read if File.exists? manifest_path
        @manifest ||= Checkm::Manifest.new data, :path => data_path
      end

      def manifest!
        @manifest = nil
        manifest
      end
    end

    class Empty < Dir

      def self.mkdir path, integer = 0777, args = {}
        super path, integer
	File.open(File.join(path, 'empty.txt')) do |f|
          f << "empty"
	end
      end

      def list
        []
      end
    end

    class Full < Dir
      include Namaste::Mixin
      include LockIt::Mixin

      DATA_DIR = 'full'

      def self.mkdir path, integer = 0777, args = {}
        super path, integer
	d = Full.new path
	Dnatural::Dir.mkdir File.join(d.path, 'full')
        d
      end

      def list
        manifest.entries.map { |e| e.sourcefileorurl }
      end

      def add src, dest, options = {}
        file = FileUtils.cp src, File.join(data_path, dest), options

        manifest!
        lock
        m = manifest.add dest, :base => data_path
        File.open(File.join(path, 'manifest.txt'), 'w') do |f|
          f.write(m.to_s)
        end
        
        unlock
        File.new File.join(data_path, dest)
      end

      def remove list, options = {}
        list = [list] if list.instance_of? String
        FileUtils.rm list.map { |x| File.join(data_path, x) }, options

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

      private
      def data_path
        File.join(self.path, DATA_DIR)
      end
      def manifest_path
        File.join(path, 'manifest.txt')
      end

    end
  end
end
