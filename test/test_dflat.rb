require 'helper'
require 'tempfile'

class TestDflat < Test::Unit::TestCase
  context "Dflat home" do
    setup do
      t = Tempfile.new 'dflat'
      d = File.dirname t.path

      FileUtils.rm_rf File.join(d, 'test')
      @dflat = Dflat::Home.mkdir File.join(d, 'test')
    end

    should "contain core files" do
      files = []
      Dir.chdir(@dflat.path) do
        files = Dir.glob(File.join('**', '*'))
      end
      assert_contains(files, '0=dflat_0.19')
      assert_contains(files, 'current.txt')
      assert_contains(files, 'dflat-info.txt')
      assert_contains(files, 'v001')
      assert_contains(files, 'v001/full/0=dnatural_0.17')
    end

    should "point to versioned content" do
      assert_equal(File.basename(@dflat.current.path), 'v001')
      assert_equal(open(File.join(@dflat.path, 'current.txt')).read, 'v001')
    end


    should "have dflat info" do
      info = @dflat.info
      assert_equal(info[:objectScheme], 'Dflat/0.19')
    end

    should "update dflat info" do
      info = @dflat.info
      info[:test] = 'abcdef'
      @dflat.info = info
      info = @dflat.info
      assert_equal(info[:test], 'abcdef')
    end

    should "add file to current version" do
      file = @dflat.current.add 'LICENSE.txt', 'producer/abcdef'
      lines = @dflat.current.manifest!.to_s.split "\n"
      assert_equal(lines[0], '#%checkm_0.7')
      assert_match(/producer\/abcdef/, lines[1])
      assert_equal(@dflat.current.manifest.valid?, true)
    end

    should "remove file from current version" do
      file = @dflat.current.add 'LICENSE.txt', 'producer/abcdef'
      @dflat.current.remove 'producer/abcdef'
      lines = @dflat.current.manifest!.to_s.split "\n"
      assert_equal(lines.length, 1)
      assert_equal(lines[0], '#%checkm_0.7')
    end

    should "do basic dnatural versioning" do
      version = @dflat.checkout

      assert_equal(@dflat.current.version, 'v001')
      assert_equal(open(File.join(@dflat.path, 'current.txt')).read, 'v001')
                  
      @dflat.commit

      assert_equal(version.version, 'v002')
      assert_equal(open(File.join(@dflat.path, 'current.txt')).read, 'v002')
    end

    should "handle ReDD versioning" do

      previous = @dflat.current
      version = @dflat.checkout
      @dflat.commit!
      
      assert(File.exists? File.join(previous.path, 'delta'))
    end

    should "handle ReDD adds" do

      previous = @dflat.current
      version = @dflat.checkout
      version.add 'LICENSE.txt', 'producer/abcdef'
      @dflat.commit!
      
      assert(File.exists? File.join(previous.path, 'delta'))
      assert_equal(open(File.join(previous.path, 'delta', 'delete.txt')).read, 'producer/abcdef')
    end

    should "handle ReDD removes" do
      previous = @dflat.current
      previous.add 'LICENSE.txt', 'producer/abcdef'
      version = @dflat.checkout
      version.remove 'producer/abcdef'
      @dflat.commit!
      
      assert(File.exists? File.join(previous.path, 'delta', 'add', 'producer', 'abcdef'))
    end

    should "handle ReDD modifies" do
      previous = @dflat.current
      previous.add 'LICENSE.txt', 'producer/abcdef'
      version = @dflat.checkout
      version.add 'README.rdoc', 'producer/abcdef'
      @dflat.commit!
      
      assert(File.exists? File.join(previous.path, 'delta', 'add', 'producer', 'abcdef'))
      assert_equal(open(File.join(previous.path, 'delta', 'delete.txt')).read, 'producer/abcdef')
    end

  end
end
