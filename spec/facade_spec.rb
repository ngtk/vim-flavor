require 'bundler/setup'
require 'fileutils'
require 'vim-flavor'

describe Vim::Flavor::Facade do
  describe '#initialize' do
    it 'should have proper values by default' do
      facade = described_class.new()
      facade.flavorfile.should == nil
      facade.flavorfile_path.should == "#{Dir.getwd()}/VimFlavor"
      facade.lockfile.should == nil
      facade.lockfile_path.should == "#{Dir.getwd()}/VimFlavor.lock"
    end
  end

  describe '#load' do
    before :each do
      @tmp_path = "#{Vim::Flavor::DOT_PATH}/tmp"
      @facade = described_class.new()
      @facade.flavorfile_path = "#{@tmp_path}/VimFlavor"
      @facade.lockfile_path = "#{@tmp_path}/VimFlavor.lock"

      @flavor1 = Vim::Flavor::Flavor.new()
      @flavor1.groups = [:default]
      @flavor1.repo_name = 'kana/vim-smartinput'
      @flavor1.repo_uri = 'git://github.com/kana/vim-smartinput.git'
      @flavor1.version_contraint =
        Vim::Flavor::VersionConstraint.new('>= 0')
      @flavor2 = Vim::Flavor::Flavor.new()
      @flavor2.groups = [:default]
      @flavor2.repo_name = 'kana/vim-smarttill'
      @flavor2.repo_uri = 'git://github.com/kana/vim-smarttill.git'
      @flavor2.version_contraint =
        Vim::Flavor::VersionConstraint.new('>= 0')

      FileUtils.mkdir_p(@tmp_path)
      File.open(@facade.flavorfile_path, 'w') do |f|
        f.write(<<-'END')
          flavor 'kana/vim-smartinput'
          flavor 'kana/vim-smarttill'
        END
      end
      File.open(@facade.lockfile_path, 'w') do |f|
        f.write(<<-'END')
          :flavors:
            - foo
            - bar
        END
      end
    end

    after :each do
      FileUtils.rm_rf([Vim::Flavor::DOT_PATH], :secure => true)
    end

    it 'should load both files' do
      @facade.load()

      @facade.flavorfile_path.should == "#{@tmp_path}/VimFlavor"
      @facade.lockfile_path.should == "#{@tmp_path}/VimFlavor.lock"
      @facade.flavorfile.flavors.keys.length == 2
      @facade.flavorfile.flavors[@flavor1.repo_uri].should == @flavor1
      @facade.flavorfile.flavors[@flavor2.repo_uri].should == @flavor2
      @facade.lockfile.flavors.should == ['foo', 'bar']
    end

    it 'should load a lockfile if it exists' do
      @facade.load()

      @facade.lockfile.flavors.should == ['foo', 'bar']

      @facade.lockfile_path = "#{@tmp_path}/VimFlavor.lock.xxx"
      @facade.load()

      @facade.lockfile.flavors.should == {}
    end
  end

  describe '#make_new_flavors' do
    before :each do
      @facade = described_class.new()

      @f0 = Vim::Flavor::Flavor.new()
      @f0.repo_name = 'kana/vim-textobj-entire'
      @f0.repo_uri = 'git://github.com/kana/vim-textobj-entire.git'
      @f0.version_contraint = Vim::Flavor::VersionConstraint.new('>= 0')
      @f0.locked_version = Gem::Version.create('0')

      @f1 = @f0.dup()
      @f1.locked_version = Gem::Version.create('2')

      @f1d = @f1.dup()
      @f1d.version_contraint = Vim::Flavor::VersionConstraint.new('>= 1')
    end

    it 'should keep current locked_version for newly added flavors' do
      @facade.make_new_flavors(
        {
          @f0.repo_uri => @f0,
        },
        {
        },
        :install
      ).should == {
        @f0.repo_uri => @f0,
      }
    end

    it 'should keep current locked_version for flavors with new constraint' do
      @facade.make_new_flavors(
        {
          @f1d.repo_uri => @f1d,
        },
        {
          @f0.repo_uri => @f0,
        },
        :install
      ).should == {
        @f1d.repo_uri => @f1d,
      }
    end

    it 'should keep current locked_version for :update mode' do
      @facade.make_new_flavors(
        {
          @f1.repo_uri => @f1,
        },
        {
          @f0.repo_uri => @f0,
        },
        :update
      ).should == {
        @f1.repo_uri => @f1,
      }
    end

    it 'should keep locked flavors otherwise' do
      @facade.make_new_flavors(
        {
          @f1.repo_uri => @f1,
        },
        {
          @f0.repo_uri => @f0,
        },
        :install
      ).should == {
        @f0.repo_uri => @f0,
      }
    end

    it 'should always use current groups even if locked version is updated' do
      f0 = @f0.dup()
      f0.groups = [:default]
      f1 = @f1.dup()
      f1.groups = [:default, :development]
      f1d = f1.dup()
      f1d.locked_version = f0.locked_version

      @facade.make_new_flavors(
        {
          f1.repo_uri => f1,
        },
        {
          f0.repo_uri => f0,
        },
        :install
      ).should == {
        f1d.repo_uri => f1d,
      }
    end
  end
end