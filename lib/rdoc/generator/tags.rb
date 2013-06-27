##
# A TAGS file generator for vim-style tags (based on
# http://ctags.sourceforge.net/FORMAT) and emacs-style tags.  Tags is
# compatible with Exuberant Ctags for merging tag definitions.
#
# This file will be automatically loaded via rdoc/discover.rb.  If you wish to
# load this standalone, require 'rdoc/rdoc' first.

class RDoc::Generator::Tags

  ##
  # The version of the tags generator you are using

  VERSION = '1.3'

  RDoc::RDoc.add_generator self

  ##
  # Extra Tags options to be added to RDoc::Options

  module Options

    ##
    # Valid tag styles

    TAG_STYLES = [
      :emacs,
      :vim
    ]

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
  # Output tag style.  See Options::TAG_STYLES for allowed values

  attr_accessor :tag_style

  ##
  # Adds tags-generator options to the RDoc::Options instance +options+

  def self.setup_options options
    options.force_output = !File.exist?('TAGS')
    options.force_update = false
    options.op_dir = File.expand_path './.rdoc'
    options.update_output_dir = true

    options.extend Options

    options.tag_style = :vim

    op = options.option_parser

    op.separator nil
    op.separator 'tags generator options:'
    op.separator nil

    op.on('--[no-]ctags-merge',
          'Merge exuberant ctags with our own?',
          'Use this for projects with C extensions') do |value|
      options.ctags_merge = value
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

  def initialize store, options
    @store = store
    @options = options

    @tag_style   = options.tag_style
    @ctags_merge = options.ctags_merge
    @ctags_path  = options.ctags_path
    @dry_run     = options.dry_run
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
  # Generates a TAGS file

  def generate
    @store.save unless @dry_run

    case @tag_style
    when 'vim',   :vim   then generate_vim
    when 'emacs', :emacs then generate_emacs
    else
      raise RDoc::Error, "Unkown tag style #{@tag_style.inspect}"
    end
  end

  ##
  # Generates an emacs TAGS file

  def generate_emacs
    # file_name => [definition, tag_name, line_number, byte_offset]
    tags = Hash.new { |h, file| h[file] = [] }

    @store.all_files.each do |top_level|
      tags[top_level.relative_name] << ['', top_level.relative_name, 0, 0]
    end

    @store.all_classes_and_modules.each do |klass|
      klass.in_files.each do |file|
        tags[file.relative_name] << [klass.definition, klass.full_name, 0, 0]
      end

      klass.each_attribute do |attr|
        tags[attr.file.relative_name] <<
          ["#{attr.definition} :#{attr.name}", attr.name, 0, 0]
      end

      klass.each_constant do |constant|
        tags[constant.file.relative_name] <<
          [constant.name, constant.name, 0, 0]
      end

      klass.each_method do |method|
        definition = if method.singleton then
                       "def self.#{method.name}"
                     else
                       "def #{method.name}"
                     end

        tags[method.file.relative_name] << [definition, method.name, 0, 0]
      end
    end

    unless @dry_run then
      write_tags_emacs tags
      merge_ctags
    end
  end

  ##
  # Generates a vim TAGS file

  def generate_vim
    tags = Hash.new { |h, name| h[name] = [] }

    @store.all_files.each do |top_level|
      tags[top_level.relative_name] << [top_level.relative_name, 0, 'F']
    end

    @store.all_classes_and_modules.each do |klass|
      kind = "class:#{klass.full_name}"

      address =
        unless RDoc::TopLevel === klass.parent then
          "/#{klass.type} \\(#{klass.parent.full_name}::\\)\\?#{klass.name}/"
        else
          "/#{klass.type} #{klass.full_name}/"
        end

      klass.in_files.each do |file|
        tags[klass.full_name] << [file.relative_name, address, 'c']
        tags[klass.name]      << [file.relative_name, address, 'c']
      end

      klass.each_attribute do |attr|
        where = [
          attr.file.relative_name,
          "/attr\\w\\*\\s\\*\\[:'\"]#{attr.name}/",
          'f',
          kind
        ]

        tags[attr.name]       << where
        tags["#{attr.name}="] << where
      end

      klass.each_constant do |constant|
        tags[constant.name] << [
          constant.file.relative_name, "/#{constant.name}\\s\\*=/", 'd', kind]
      end

      klass.each_method do |method|
        address = if method.singleton then
                    # \w doesn't appear to work in [] with nomagic
                    "/def \\[A-Za-z0-9_:]\\+.#{method.name}/"
                  else
                    "/def #{method.name}/"
                  end

        tags[method.name] << [
          method.file.relative_name, address, 'f', kind]
      end
    end

    unless @dry_run then
      write_tags_vim tags
      merge_ctags
    end
  end

  ##
  # Merges our tags with Exuberant Ctags' tags

  def merge_ctags
    return unless @ctags_merge

    ctags_path = @ctags_path || find_ctags

    ctags_args = [
      '--append=yes',
      '--format=2',
      '--languages=-Ruby',
      '--recurse=yes',
      *@options.files
    ]

    ctags_args.unshift '-e' if @tag_style == :emacs

    unless @options.quiet then
      puts
      puts 'Merging with Exuberant Ctags'
      puts "#{ctags_path} #{ctags_args.join ' '}"
    end

    Dir.chdir '..' do
      system ctags_path, *ctags_args
    end
  end

  ##
  # Writes the TAGS file in emacs style using the data in +tags+

  def write_tags_emacs tags
    open '../TAGS', 'wb' do |io|
      tags.sort.each do |file, definitions|
        section = []

        definitions.sort.each do |(definition, tag_name, line, offset)|
          section << "#{definition}\x7F#{tag_name}\x01#{line},#{offset}"
        end

        section = section.join "\n"

        io << "\x0C\n#{file},#{section.length}\n#{section}\n"
      end
    end
  end

  ##
  # Writes the TAGS file in vim style using the data in +tags+

  def write_tags_vim tags
    open '../TAGS', 'w' do |io|
      io.write <<-INFO
!_TAG_FILE_FORMAT\t2\t/extended format/
!_TAG_FILE_SORTED\t1\t/sorted/
!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/
!_TAG_PROGRAM_NAME\trdoc-tags\t//
!_TAG_PROGRAM_URL\thttps://github.com/rdoc/rdoc-tags\t//
!_TAG_PROGRAM_VERSION\t#{VERSION}\t//
      INFO

      tags.sort.each do |name, definitions|
        definitions = definitions.uniq

        definitions = definitions.sort_by do |(file, address,*_)|
          [file, address]
        end

        definitions.each do |(file, address, *field)|
          io.write "#{name}\t#{file}\t#{address};\"\t#{field.join "\t"}\n"
        end
      end
    end
  end

end

