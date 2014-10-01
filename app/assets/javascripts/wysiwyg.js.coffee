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
#= require bootstrap-wysihtml5/locales/fr-FR
#= require bootstrap-wysihtml5/locales/it-IT



$ ->

  languages =
    "de-DE": "Überschrift"
    "fr-FR": "Titre"
    "it-IT": "Titolo"

  # Add missing translation keys
  for lang, title of languages
    for num in [1..6]
      $.fn.wysihtml5.locale[lang].font_styles["h#{num}"] = "#{title} #{num}"

  wysilocale = do ->
    lang = $('html').attr('lang')
    lang + '-' + lang.toUpperCase()

  # wire up wysiwyg text areas
  $('textarea.wysiwyg').wysihtml5({
    locale: wysilocale
  });

