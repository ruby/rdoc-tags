# -*- ruby -*-

require 'rubygems'
require 'hoe'

$:.unshift 'lib' # allow rdoc-tags to tag itself

Hoe.plugin :git
Hoe.plugin :minitest
Hoe.plugin :rdoc_tags unless ENV['TRAVIS']
Hoe.plugin :travis

Hoe.spec 'rdoc-tags' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  dependency 'rdoc', '~> 4'

  rdoc_locations <<
    'drbrain@rubyforge.org:/var/www/gforge-projects/rdoc/rdoc-tags'
  rdoc_locations <<
    'docs.seattlerb.org:/data/www/docs.seattlerb.org/rdoc-tags'
end

# vim: syntax=Ruby
