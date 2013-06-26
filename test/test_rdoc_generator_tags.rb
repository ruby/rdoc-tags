require 'rubygems'
gem 'rdoc', '>= 4.0.0.preview2', '< 5'

require 'minitest/autorun'
require 'rdoc/rdoc'
require 'rdoc/generator/tags'
require 'tmpdir'
require 'fileutils'

class TestRDocGeneratorTags < MiniTest::Unit::TestCase

  def setup
    @options = RDoc::Options.new
    @options.extend RDoc::Generator::Tags::Options

    @pwd = Dir.pwd

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_generator_tags_#{$$}"
    FileUtils.mkdir_p @tmpdir
    Dir.chdir @tmpdir

    @store = RDoc::Store.new
    @g = RDoc::Generator::Tags.new @store, @options

    @top_level = @store.add_file 'file.rb'

    @klass = @top_level.add_class RDoc::NormalClass, 'Object'
    @klass.record_location @top_level

    @A = @top_level.add_class RDoc::NormalClass, 'A'
    @A.record_location @top_level

    @B = @A.add_class RDoc::NormalClass, 'B'
    @B.record_location @top_level

    @meth = RDoc::AnyMethod.new nil, 'method'
    @meth.record_location @top_level

    @meth_bang = RDoc::AnyMethod.new nil, 'method!'
    @meth_bang.record_location @top_level

    @attr = RDoc::Attr.new nil, 'attr', 'RW', ''
    @attr.record_location @top_level

    @smeth = RDoc::AnyMethod.new nil, 's_method'
    @smeth.singleton = true
    @smeth.record_location @top_level

    @const = RDoc::Constant.new 'CONST', '', ''
    @const.record_location @top_level

    @klass.add_method @meth
    @klass.add_method @smeth
    @klass.add_method @meth_bang
    @klass.add_attribute @attr
    @klass.add_constant @const

    @top_level_2 = RDoc::TopLevel.new 'file_2.rb'
    @A_B_A = @B.add_class RDoc::NormalClass, 'A'
    @A_B_A.record_location @top_level_2
  end

  def teardown
    Dir.chdir @pwd
    FileUtils.rm_rf @tmpdir
  end

  def test_class_setup_options
    options = RDoc::Options.new

    op = OptionParser.new

    options.option_parser = op

    RDoc::Generator::Tags.setup_options options

    assert_equal :vim, options.tag_style

    assert_includes op.top.long, 'ctags-path'
    assert_includes op.top.long, 'ctags-merge'
    assert_includes op.top.long, 'tag-style'
    refute options.update_output_dir
  end

  def test_find_ctags
    assert_match 'ctags', @g.find_ctags
  end

  def test_generate_emacs
    @g.tag_style = :emacs

    @g.generate

    tags_file = File.join @tmpdir, 'TAGS'

    assert File.file? tags_file

    tags = open tags_file, 'rb' do |io| io.read end.each_line

    assert_equal "\f\n",          tags.next
    assert_equal "file.rb,192\n", tags.next

    assert_equal "\x7Ffile.rb\x010,0\n", tags.next

    assert_equal "CONST\x7FCONST\x010,0\n", tags.next

    assert_equal "attr_accessor :attr\x7Fattr\x010,0\n", tags.next

    assert_equal "class A\x7FA\x010,0\n",           tags.next
    assert_equal "class A::B\x7FA::B\x010,0\n",     tags.next
    assert_equal "class Object\x7FObject\x010,0\n", tags.next

    assert_equal "def method\x7Fmethod\x010,0\n",          tags.next
    assert_equal "def method!\x7Fmethod!\x010,0\n",        tags.next
    assert_equal "def self.s_method\x7Fs_method\x010,0\n", tags.next

    assert_equal "\f\n",           tags.next
    assert_equal "file_2.rb,25\n", tags.next

    assert_equal "class A::B::A\x7FA::B::A\x010,0\n", tags.next

    assert_raises StopIteration do line = tags.next; flunk line end
  end

  def test_generate_vim
    @g.tag_style = :vim

    @g.generate

    tags_file = File.join @tmpdir, 'TAGS'

    assert File.file? tags_file

    tags = File.read(tags_file).each_line

    assert_equal "!_TAG_FILE_FORMAT\t2\t/extended format/\n", tags.next
    assert_equal "!_TAG_FILE_SORTED\t1\t/sorted/\n", tags.next
    assert_equal "!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_NAME\trdoc-tags\t//\n", tags.next
    assert_equal "!_TAG_PROGRAM_URL\thttps://github.com/rdoc/rdoc-tags\t//\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_VERSION\t#{RDoc::Generator::Tags::VERSION}\t//\n",
                 tags.next

    assert_equal "A\tfile.rb\t/class A/;\"\tc\n",                  tags.next
    assert_equal "A\tfile_2.rb\t/class \\(A::B::\\)\\?A/;\"\tc\n", tags.next
    assert_equal "A::B\tfile.rb\t/class \\(A::\\)\\?B/;\"\tc\n",   tags.next
    assert_equal "A::B::A\tfile_2.rb\t/class \\(A::B::\\)\\?A/;\"\tc\n",
                 tags.next
    assert_equal "B\tfile.rb\t/class \\(A::\\)\\?B/;\"\tc\n",      tags.next

    assert_equal "CONST\tfile.rb\t/CONST\\s\\*=/;\"\td\tclass:Object\n",
                 tags.next

    assert_equal "Object\tfile.rb\t/class Object/;\"\tc\n", tags.next

    assert_equal "attr\tfile.rb\t/attr\\w\\*\\s\\*\\[:'\"]attr/;\"\tf\tclass:Object\n",
                 tags.next
    assert_equal "attr=\tfile.rb\t/attr\\w\\*\\s\\*\\[:'\"]attr/;\"\tf\tclass:Object\n",
                 tags.next

    assert_equal "file.rb\tfile.rb\t0;\"\tF\n", tags.next

    assert_equal "method\tfile.rb\t/def method/;\"\tf\tclass:Object\n",
                 tags.next
    assert_equal "method!\tfile.rb\t/def method!/;\"\tf\tclass:Object\n",
                 tags.next

    assert_equal "s_method\tfile.rb\t/def \\[A-Za-z0-9_:]\\+.s_method/;\"\tf\tclass:Object\n",
                 tags.next

    assert_raises StopIteration do line = tags.next; flunk line end
  end

  def test_generate_dry_run_vim
    @options.tag_style = :vim
    @options.dry_run = true
    @g = RDoc::Generator::Tags.new @store, @options

    @g.generate

    refute File.exist? File.join(@tmpdir, 'TAGS')
  end

  def test_merge_ctags
    def @g.system(*args)
      @system = args
    end

    @g.instance_variable_set :@system, nil

    assert_silent do
      @g.merge_ctags
    end

    assert_nil @g.instance_variable_get :@system

    @g.ctags_merge = true
    @g.ctags_path = 'ctags'
    @options.files = '.'

    capture_io do
      @g.merge_ctags
    end

    args = @g.instance_variable_get :@system

    assert_equal %w[ctags
                    --append=yes --format=2 --languages=-Ruby --recurse=yes
                    .], args
  end

end

