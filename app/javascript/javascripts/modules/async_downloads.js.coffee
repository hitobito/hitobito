# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

import Cookies from 'js-cookie'

app = window.App ||= {}

class app.AsyncDownloads

  constructor: () ->
    bind.call()
    setInterval(( -> checkDownloadCookie()), 500)
    setInterval(( -> checkDownload()), 5000)

  checkDownloadCookie = ->
    if Cookies.get('async_downloads') == undefined
      $('#file-download-spinner').addClass('hidden')
      return

  checkDownload = ->
    return if Cookies.get('async_downloads') == undefined
    $('#file-download-spinner').removeClass('hidden')
    $.each JSON.parse(Cookies.get('async_downloads')), (index, download) ->
      $.ajax(
        url: "/downloads/#{download['name']}/exists",
        data: "file_type=#{download['type']}",
        success: (data) ->
          if data['progress']
            $('#file-download-spinner .progress').removeClass('hidden').html("#{data['progress']}%")

          return if data['status'] != 200
          download_file("/downloads/#{download['name']}?file_type=#{download['type']}")
      )

  download_file = (url) ->
    window.location.href = url

  bind = ->
    $(document).ready ->
      checkDownload()

    $(document).on 'click', '#cancel_async_downloads', (e) ->
      Cookies.remove('async_downloads', { path: '/' })

  new AsyncDownloads
