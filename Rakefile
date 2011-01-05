# -*- ruby -*-

require 'rubygems'
require 'hoe'

$:.unshift 'lib' # allow rdoc-tags to tag itself

Hoe.plugin :git
Hoe.plugin :isolate
Hoe.plugin :minitest
Hoe.plugin :rdoc_tags
Hoe.plugins.delete :rubyforge

Hoe.spec 'rdoc-tags' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  extra_deps << ['rdoc', '~> 3.4'] # don't forget to update rdoc/discover.rb
  extra_dev_deps << ['isolate', '~> 3']

  self.isolate_dir = 'tmp/isolate'
  self.rdoc_locations =
    'drbrain@rubyforge.org:/var/www/gforge-projects/rdoc/rdoc-tags'
end

# vim: syntax=Ruby
