require 'rdoc/rdoc'
require 'rdoc/generator'

##
# A TAGS file generator based on http://ctags.sourceforge.net/FORMAT

class RDoc::Generator::Tags

  ##
  # The version of the tags generator you are using

  VERSION = '1.1'

  RDoc::RDoc.add_generator self

  ##
  # Extra Tags options to be added to RDoc::Options

  module Options

    ##
    # Valid tag styles

    TAG_STYLES = [:vim]

    ##
    # Which tag style shall we output?

    attr_accessor :tag_style

  end

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
    @dry_run = options.dry_run
    @tags = {}
  end

  ##
  # Generates a TAGS file from +top_levels+

  def generate top_levels
    top_levels.each do |top_level|
      @tags[top_level.relative_name] = [top_level.relative_name, 0, 'F']
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
        @tags[klass.full_name] = [file.relative_name, address, 'c']
        @tags[klass.name]      = [file.relative_name, address, 'c']
      end

      klass.each_attribute do |attr|
        where = [
          attr.file.relative_name,
          "/attr\\w\\*\\s\\*\\[:'\"]#{attr.name}/",
          'f',
          kind
        ]
        
        @tags[attr.name]       = where
        @tags["#{attr.name}="] = where
      end

      klass.each_constant do |constant|
        @tags[constant.name] = [
          constant.file.relative_name, "/#{constant.name}\\s\\*=/", 'd', kind]
      end

      klass.each_method do |method|
        address = if method.singleton then
                    # \w doesn't appear to work in [] with nomagic
                    "/def \\[A-Za-z0-9_:]\\+.#{method.name}/"
                  else
                    "/def #{method.name}/"
                  end

        @tags[method.name] = [
          method.file.relative_name, address, 'f', kind]
      end
    end

    write_tags unless @dry_run
  end

  ##
  # Writes the TAGS file

  def write_tags
    open 'TAGS', 'w' do |io|
      io.write <<-INFO
!_TAG_FILE_FORMAT\t2
!_TAG_FILE_SORTED\t1
!_TAG_PROGRAM_AUTHOR\tEric Hodel\t/drbrain@segment7.net/
!_TAG_PROGRAM_NAME\trdoc-tags
!_TAG_PROGRAM_URL\thttps://github.com/rdoc/rdoc-tags
!_TAG_PROGRAM_VERSION\t#{VERSION}
      INFO

      @tags.sort.each do |name, (file, address, *field)|
        io.write "#{name}\t#{file}\t#{address};\"\t#{field.join "\t"}\n"
      end
    end
  end

end

