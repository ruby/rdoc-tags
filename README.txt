= rdoc-tags

* https://github.com/rdoc/rdoc-tags
* http://rdoc.rubyforge.org/rdoc-tags

== Description

A TAGS file generator that builds both vim and emacs style tags files. Vim
tags are based on http://ctags.sourceforge.net/FORMAT).  rdoc-tags is
compatible with Exuberant Ctags for merging tag definitions.

rdoc-tags includes a Hoe plugin +:rdoc_tags+ making it easy to add tag support
to your ruby project.  If you don't use Hoe you can instead use RDoc::TagsTask
to add rake tasks for building TAGS to your ruby project.

== Features

* Better ruby support than Exuberant Ctags
* Generates vim-format tags
* Generates emacs-format tags
* Slower than Exuberant Ctags on the first run

== Synopsis

Vim-style tags:

  rdoc -f tags lib

Emacs-style tags:

  rdoc -f tags --tag-style=emacs lib

== Requirements

* RDoc 4+

== Install

* gem install rdoc-tags

== License

(The MIT License)

Copyright (c) Eric Hodel

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
