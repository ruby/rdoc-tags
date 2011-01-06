##
# A TAGS file generator based on http://ctags.sourceforge.net/FORMAT
#
# This file will be automatically loaded via rdoc/discover.rb.  If you wish to
# load this standalone, require 'rdoc/rdoc' first.

class RDoc::Generator::Tags

  ##
  # The version of the tags generator you are using

  VERSION = '1.2'

  RDoc::RDoc.add_generator self

  ##
  # Extra Tags options to be added to RDoc::Options

  module Options

    ##
    # Valid tag styles

    TAG_STYLES = [:vim]

    ##
    # Merge ctags-generated tags onto our own?

    attr_accessor :ctags_merge

    ##
    # Path to Exuberant Ctags

    attr_accessor :ctags_path

    ##
    # Which tag style shall we output?

    attr_accessor :tag_style

  end

  ##
  # Merge with Exuberant Ctags if true

  attr_accessor :ctags_merge

  ##
  # Path to Exuberant Ctags

  attr_accessor :ctags_path

  ##
  # Adds tags-generator options to the RDoc::Options instance +options+

  def self.setup_options options
    options.force_output = true
    options.op_dir = '.'

    options.extend Options

    options.tag_style = :vim

    op = options.option_parser

    op.separator nil
    op.separator 'tags generator options:'
    op.separator nil

    op.on('--[no-]ctags-merge',
          'Merge exuberant ctags with our own?',
          'Use this for projects with C extensions') do |value|
      options.ctags_path = value
    end

    op.separator nil

    op.on('--ctags-path=PATH',
          'Path to Exuberant Ctags',
          'This will be auto-discovered from PATH') do |value|
      options.ctags_path = value
    end

    op.separator nil

    op.on('--tag-style=TAG_STYLE', Options::TAG_STYLES,
          'Which type of TAGS file to output') do |value|
      options.tag_style = value
    end

    op.separator nil
  end

  ##
  # Creates a new tags generator

  def initialize options
    @options = options

    @ctags_merge = options.ctags_merge
    @ctags_path  = options.ctags_path
    @dry_run     = options.dry_run

    @tags = Hash.new { |h, name| h[name] = [] }
  end

  ##
  # Finds the first Exuberant Ctags in ENV['PATH'] by checking <tt>ctags
  # --version</tt>.  Other implementations are ignored.

  def find_ctags
    require 'open3'

    ENV['PATH'].split(File::PATH_SEPARATOR).each do |dir|
      ctags = File.join dir, 'ctags'
      next unless File.exist? ctags

      # other ctags implementations write to stderr, silence them
      return ctags if Open3.popen3 ctags, '--version' do |_, out, _|
        out.gets =~ /^Exuberant Ctags/
      end
    end

    nil
  end

  ##
  # Generates a TAGS file from +top_levels+

  def generate top_levels
    top_levels.each do |top_level|
      @tags[top_level.relative_name] << [top_level.relative_name, 0, 'F']
    end

    RDoc::TopLevel.all_classes_and_modules.each do |klass|
      kind = "class:#{klass.full_name}"

      address =
        unless RDoc::TopLevel === klass.parent then
          "/#{klass.type} \\(#{klass.parent.full_name}::\\)\\?#{klass.name}/"
        else
          "/#{klass.type} #{klass.full_name}/"
        end

      klass.in_files.each do |file|
        @tags[klass.full_name] << [file.relative_name, address, 'c']
        @tags[klass.name]      << [file.relative_name, address, 'c']
      end

      klass.each_attribute do |attr|
        where = [
          attr.file.relative_name,
          "/attr\\w\\*\\s\\*\\[:'\"]#{attr.name}/",
          'f',
          kind
        ]

        @tags[attr.name]       << where
        @tags["#{attr.name}="] << where
      end

      klass.each_constant do |constant|
        @tags[constant.name] << [
          constant.file.relative_name, "/#{constant.name}\\s\\*=/", 'd', kind]
      end

      klass.each_method do |method|
        address = if method.singleton then
                    # \w doesn't appear to work in [] with nomagic
                    "/def \\[A-Za-z0-9_:]\\+.#{method.name}/"
                  else
                    "/def #{method.name}/"
                  end

        @tags[method.name] << [
          method.file.relative_name, address, 'f', kind]
      end
    end

    unless @dry_run then
      write_tags
      merge_ctags
    end
  end

  ##
  # Merges our tags with Exuberant Ctags' tags

  def merge_ctags
    return unless @ctags_merge

    ctags_path = @ctags_path || find_ctags

    system(ctags_path, '--append=yes', '--format=2', '--languages=-Ruby',
           '--recurse=yes', *@options.files)
  end

  ##
  # Writes the TAGS file

  def write_tags
    open 'TAGS', 'w' do |io|
      io.write <<-INFO
!_TAG_FILE_FORMAT\t2\t/extended format/
!_TAG_FILE_SORTED\t1\t/sorted/
!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/
!_TAG_PROGRAM_NAME\trdoc-tags\t//
!_TAG_PROGRAM_URL\thttps://github.com/rdoc/rdoc-tags\t//
!_TAG_PROGRAM_VERSION\t#{VERSION}\t//
      INFO

      @tags.sort.each do |name, definitions|
        definitions.uniq.each do |(file, address, *field)|
          io.write "#{name}\t#{file}\t#{address};\"\t#{field.join "\t"}\n"
        end
      end
    end
  end

end

