require 'rubygems'
gem 'rdoc', '~> 3'

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
    RDoc::TopLevel.reset

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_generator_tags_#{$$}"
    FileUtils.mkdir_p @tmpdir
    Dir.chdir @tmpdir

    @g = RDoc::Generator::Tags.new @options

    @top_level = RDoc::TopLevel.new 'file.rb'

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

    assert_includes op.top.long, 'tag-style'
  end

  def test_generate_emacs
    skip "test incomplete"

    @options.tag_style = :emacs

    @g.generate [@top_level]

    tags_file = File.join @tmpdir, 'TAGS'

    assert File.file? tags_file

    tags = File.read(tags_file).lines

    assert_equal "!_TAG_FILE_FORMAT\t2\n", tags.next
    assert_equal "!_TAG_FILE_SORTED\t1\n", tags.next
    assert_equal "!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_NAME\trdoc-tags\n", tags.next
    assert_equal "!_TAG_PROGRAM_URL\thttp://rdoc.rubyforge.org/rdoc-tags\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_VERSION\t#{RDoc::Generator::Tags::VERSION}\n",
                 tags.next

    assert_equal "A\tfile.rb\t/class A/;\"\tc\n",                tags.next
    assert_equal "A::B\tfile.rb\t/class \\(A::\\)\\?B/;\"\tc\n", tags.next
    assert_equal "B\tfile.rb\t/class \\(A::\\)\\?B/;\"\tc\n",    tags.next

    assert_equal "CONST\tfile.rb\t/CONST\\s\\*=/;\"\td\tclass:Object\n", tags.next

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

  def test_generate_vim
    @options.tag_style = :vim

    @g.generate [@top_level]

    tags_file = File.join @tmpdir, 'TAGS'

    assert File.file? tags_file

    tags = File.read(tags_file).lines

    assert_equal "!_TAG_FILE_FORMAT\t2\n", tags.next
    assert_equal "!_TAG_FILE_SORTED\t1\n", tags.next
    assert_equal "!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_NAME\trdoc-tags\n", tags.next
    assert_equal "!_TAG_PROGRAM_URL\thttps://github.com/rdoc/rdoc-tags\n",
                 tags.next
    assert_equal "!_TAG_PROGRAM_VERSION\t#{RDoc::Generator::Tags::VERSION}\n",
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

  def test_generate_dry_run
    @options.dry_run = true
    @g = RDoc::Generator::Tags.new @options

    @g.generate [@top_level]

    refute File.exist? File.join(@tmpdir, 'TAGS')
  end

end

