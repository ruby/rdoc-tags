require 'rdoc/tags_task'

##
# The RDoc tags plugin for Hoe uses the standard names +tags+, +retag+ and
# +clobber_tags+ from RDoc::TagsTask.  The plugin also integrates with the
# +clobber+ and +newb+ tasks Hoe provides to add automatic cleanup.
#
# The +tags+ task automatically builds tags using all files in your
# specification's require paths (defaults to the lib directory).
#
# When the +newb+ task is run the plugin will automatically build a TAGS file.
#
# When the +clobber+ task is run the plugin will automatically remove the TAGS
# file.
#
# The plugin defaults to generating vim-style tags.  You can override this by
# setting a value for <tt>'tags_style'</tt> in ~/.hoerc.  Be sure to check
# <tt>rdoc --help</tt> for valid values.

module Hoe::RDoc_tags

  ##
  # Defines tasks for building and removing TAGS files that integrate with
  # Hoe.

  def define_rdoc_tags_tasks
    ctags_merge = false
    ctags_path  = nil

    with_config do |config, _|
      tag_style   = config['tag_style']
      ctags_merge = config['ctags_merge'] if config.key? 'ctags_merge'
      ctags_path  = config['ctags_path']
    end

    tag_style ||= 'vim'

    RDoc::TagsTask.new do |rd|
      rd.files += spec.require_paths

      rd.tag_style   = tag_style
      rd.ctags_merge = ctags_merge
      rd.ctags_path  = ctags_path
    end

    task :clobber => :clobber_tags
    task :newb    => :tags
  end

end

