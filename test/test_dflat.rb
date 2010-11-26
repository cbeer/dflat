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
      assert_contains(files, 'v001/0=dnatural_0.17')
    end

    should "point to versioned content" do
      assert_equal(File.basename(@dflat.current.path), 'v001')
      assert_equal(open(File.join(@dflat.path, 'current.txt')).read, 'v001')
    end

    should "do basic dnatural versioning" do
      version = @dflat.version!
      assert_equal(File.basename(version.path), 'v002')
      assert_equal(open(File.join(@dflat.path, 'current.txt')).read, 'v002')
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

  end
end
