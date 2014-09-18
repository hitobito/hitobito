#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This is a manifest file that'll be compiled into wysiwyg.js, which will include all the files
# listed below.
#
#= require bootstrap-modal
#= require bootstrap-wysihtml5
#= require bootstrap-wysihtml5/locales/de-DE


$ ->
  # wire up wysiwyg text areas
  $('textarea.wysiwyg').wysihtml5({
    locale: 'de-DE'
  });