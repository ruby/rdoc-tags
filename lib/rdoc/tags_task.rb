require 'rubygems'

begin
  gem 'rake'
rescue Gem::LoadError
end

require 'rake'
require 'rake/tasklib'

begin
  gem 'rdoc'
rescue LoadError
end
require 'rdoc'

##
# Creates rake tasks for building, rebuilding and removing TAGS files.
#
# In your Rakefile add:
#
#   require 'rdoc/tags_task'
#
#   RDoc::TagsTask.new
#
# Then run from the commandline:
#
#   $ rake tags         # build
#   $ rake retag        # rebuild
#   $ rake clobber_tags # remove
#
# Use the Hoe::RDoc_tags plugin instead if you're using Hoe.

class RDoc::TagsTask < Rake::TaskLib

  ##
  # Merge Exuberant Ctags output with our own.  See RDoc::Generator::Tags

  attr_accessor :ctags_merge

  ##
  # Path to Exuberant Ctags.  ctags will be found automatically if this is not
  # set.  See RDoc::Generator::Tags

  attr_accessor :ctags_path

  ##
  # Rake::FileList of files to be used for tag generation.
  #
  # Your gem's require paths are probably sufficient.

  attr_accessor :files

  ##
  # Directory to generate tags into.  Defaults to '.'

  attr_accessor :tags_dir

  ##
  # Name of the TAGS file.  Defaults to 'TAGS'

  attr_accessor :tags_file

  ##
  # Tag style to output.  Defaults to vim, emacs is also supported.

  attr_accessor :tag_style

  ##
  # Creates a new RDoc task that will build a TAGS file.  Default task names
  # are +tags+ to build, +retag+ to rebuild and +clobber_tags+ to remove.
  # These may be overridden using the +names+ hash with the +:tags+,
  # +:retag+ and +:clobber+ keys respectively.

  def initialize names = {} # :yield: self
    @clobber_task = names[:clobber] || 'clobber_tags'
    @retag_task   = names[:retag]   || 'retag'
    @tags_task    = names[:tags]    || 'tags'

    @files     = Rake::FileList.new
    @tags_dir  = '.'
    @tags_file = 'TAGS'
    @tag_style = 'vim'

    @ctags_merge = false
    @ctags_path  = nil

    yield self if block_given?

    define
  end

  ##
  # Builds the TAGS file.

  def build_tags
    require 'rdoc/rdoc'
    require 'rdoc/generator/tags'

    options = RDoc::Options.new
    options.setup_generator 'tags'

    options.tag_style = @tag_style

    options.ctags_merge = @ctags_merge
    options.ctags_path  = @ctags_path

    options.files = @files

    options.op_dir = @tags_dir
    options.verbosity = 0

    if Rake.application.options.trace then
      options.verbosity = 1

      # TODO RDoc::Options#to_argv?
      ctags_merge = " --ctags-merge" if @ctags_merge
      ctags_path = " --ctags_path=#{@ctags_path}" if @ctags_path
      ctags = "#{ctags_merge}#{ctags_path}"

      $stderr.puts "rdoc -o #{@tags_dir} -f tags#{ctags} #{@files}"
    end

    RDoc::RDoc.new.document options
  end

  ##
  # Defines tasks for building, rebuilding and clobbering the TAGS file

  def define
    desc 'Build TAGS file'
    task @tags_task => @tags_file

    desc 'Rebuild TAGS file'
    task @retag_task => [@clobber_task, @tags_task]

    desc 'Clobber TAGS file'
    task @clobber_task do
      rm_f tags_path, :verbose => Rake.application.options.trace
    end

    directory @tags_dir

    file @tags_file => [@tags_dir, Rake.application.rakefile, @files] do
      build_tags
    end

    self
  end

  ##
  # Path to the tags file

  def tags_path
    File.join @tags_dir, @tags_file
  end

end

