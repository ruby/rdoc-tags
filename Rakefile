# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :git
Hoe.plugin :isolate
Hoe.plugin :minitest
Hoe.plugin :rdoc_tags
Hoe.plugins.delete :rubyforge

Hoe.spec 'rdoc-tags' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  extra_deps << ['rdoc', '~> 3.2']
  extra_dev_deps << ['isolate', '~> 3']

  self.isolate_dir = 'tmp/isolate'
end

# vim: syntax=Ruby
