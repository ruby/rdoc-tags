require 'rdoc/tags_task'

##
# The RDoc tags plugin for Hoe uses the standard names +tags+, +retag+ and
# +clobber_tags+ from RDoc::TagsTask.  The plugin also integrates with the
# +clean+, +clobber+ and +newb+ tasks Hoe provides to add automatic cleanup.
#
# The +tags+ task automatically builds tags using all files in your
# specification's require paths (defaults to the lib directory).
#
# When the +newb+ task is run the plugin will automatically build a TAGS file.
#
# When the +clean+ or +clobber+ task is run the plugin will automatically
# remove the TAGS file.
#
# The plugin defaults to generating vim-style tags.  You can override this by
# setting a value for <tt>'tags_style'</tt> in ~/.hoerc.  Be sure to check
# <tt>rdoc --help</tt> for valid values.

module Hoe::RDoc_tags

  ##
  # Defines tasks for building and removing TAGS files that integrate with
  # Hoe.

  def define_rdoc_tags_tasks
    tags_style = 'vim'

    with_config do |config, _|
      tags_style = config['tags_style']
    end

    RDoc::TagsTask.new do |rd|
      rd.files += spec.require_paths
      rd.tags_style = tags_style
    end

    task :clean   => :clobber_tags
    task :clobber => :clobber_tags
    task :newb    => :tags
  end

end

