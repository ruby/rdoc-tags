# -*- ruby -*-

require 'rubygems'
require 'hoe'

$:.unshift 'lib' # allow rdoc-tags to tag itself

Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :rdoc_tags
Hoe.plugins.delete :rubyforge

Hoe.spec 'rdoc-tags' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  extra_deps << ['rdoc', '>= 4.0.0.preview2', '< 5']
  extra_dev_deps << ['ZenTest']

  rdoc_locations <<
    'drbrain@rubyforge.org:/var/www/gforge-projects/rdoc/rdoc-tags'
  rdoc_locations <<
    'docs.seattlerb.org:/data/www/docs.seattlerb.org/rdoc-tags'
end

# vim: syntax=Ruby
