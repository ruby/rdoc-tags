require 'rubygems'

begin
  gem 'rake'
rescue Gem::LoadError
end

require 'rake'
require 'rake/tasklib'

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
  # Tag style to output.  Defaults to vim.

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

    yield self if block_given?

    define
  end

  ##
  # Builds the TAGS file.

  def build_tags
    args = [
      '-f', 'tags',
      '-q',
      '--tag-style', @tag_style,
      '-o', @tags_dir,
    ]

    args += @files

    begin
      gem 'rdoc'
    rescue Gem::LoadError
    end

    require 'rdoc/rdoc'
    $stderr.puts "rdoc #{args.join ' '}" if Rake.application.options.trace

    RDoc::RDoc.new.document args
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
      rm_f tags_path
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

