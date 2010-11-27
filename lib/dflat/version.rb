require 'namaste'
require 'lockit'
require 'fileutils'
module Dflat
  module Version
    class Dir < ::Dir
      include Namaste::Mixin
      include LockIt::Mixin
     
      def self.load path
        d = Dir.new path
        return Full.new path if d.entries.any? { |f| f =~ /full/ }
        return Delta.new path if types.any? { |t| t[:name] =~ /redd/i }
	return Empty.new path
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
      DATA_DIR = 'full'

      def self.mkdir path, integer = 0777, args = {}
        super path, integer
	d = Full.new path
	Dnatural::Dir.mkdir File.join(d.path, DATA_DIR)
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

      def to_delta version
	redd = ReDD::Dir.mkdir File.join(self.path, Delta::DATA_DIR)
        delta = Delta.new self.path

	old = self.manifest.to_hash
	new = version.manifest.to_hash

	changeset = {:delete => [], :add => []}

	new.select do |filename, entry|
          changeset[:delete] << filename unless old[filename] and old[filename] == entry[filename]
	end

	old.select do |filename, entry|
          changeset[:add] << filename unless new[filename] and old[filename] == entry[filename]
	end
	
        changeset[:delete].each do |filename|
	  delta.remove filename
	end

        changeset[:add].each do |filename|
	  delta.add File.join(data_path, filename), filename
	end

	FileUtils.rm_rf data_path
	return delta
      end

      private
      def data_path
        File.join(self.path, DATA_DIR)
      end
      def manifest_path
        File.join(path, 'manifest.txt')
      end
    end
    class Delta < Dir
      DATA_DIR = 'delta'

      def self.mkdir path, integer = 0777, args = {}
        super path, integer
	d = Delta.new path
	@redd = ReDD::Dir.mkdir File.join(d.path, DATA_DIR)
        d
      end

      def initialize path
        super path
        @redd = ReDD::Dir.new File.join(path, DATA_DIR)
      end

      def add source, dest, options = {}
        manifest!
        f = @redd.add source, dest, options
        m = manifest.add dest, :base => File.join(data_path, 'add')
        File.open(File.join(path, 'manifest.txt'), 'w') do |f|
          f.write(m.to_s)
        end
        
	f
      end

      def remove list, options = {}
        list = [list] if list.instance_of? String
        @redd.remove list.map { |x| x }, options
        m = manifest!
        list.each do |l|
          m = m.remove l
        end

        File.open(File.join(path, 'manifest.txt'), 'w') do |f|
          f.write(m.to_s)
        end
      end

      private
      def data_path
        File.join(self.path, DATA_DIR)
      end
      def dmanifest_path
        File.join(path, 'd-manifest.txt')
      end
      def manifest_path
        File.join(path, 'manifest.txt')
      end
    end
  end
end
