#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# This is a manifest file that'll be compiled into wysiwyg.js, which will include all the files
# listed below.
#
#= require bootstrap-wysihtml5
#= require bootstrap-wysihtml5/locales/de-DE
#= require bootstrap-wysihtml5/locales/fr-FR
#= require bootstrap-wysihtml5/locales/it-IT

# TODO: replace with Action Text or other actively maintained WYSIWYG editor

app = window.Wysiwyg ||= {}

app.Wysiwyg = {
  setup: ->
    wysi_languages =
      "de-DE": "Überschrift"
      "fr-FR": "Titre"
      "it-IT": "Titolo"

    # Add missing translation keys
    for lang, title of wysi_languages
      for num in [1..6]
        $.fn.wysihtml5.locale[lang].font_styles["h#{num}"] = "#{title} #{num}"

    wysilocale = do ->
      lang = $('html').attr('lang')
      lang + '-' + lang.toUpperCase()


    $('textarea.wysiwyg').wysihtml5({
      locale: wysilocale,
      toolbar: {
        'fa': true,
        'image': false,
        'smallmodals': true
      }
    })
}

# See https://sevos.io/2017/02/27/turbolinks-lifecycle-explained.html
$(document).one('turbolinks:load', -> app.Wysiwyg.setup());
$(document).on('turbolinks:render', -> app.Wysiwyg.setup());
