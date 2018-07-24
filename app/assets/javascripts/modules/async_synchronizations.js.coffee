# encoding: utf-8

#  Copyright (c) 2012-2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.AsyncSynchronizations

  constructor: () ->
    bind.call()
    setInterval(( -> checkSynchronizationCookie()), 500)
    setInterval(( -> checkSynchronization()), 1000)

  checkSynchronizationCookie = ->
    if $.cookie('async_synchronizations') == null
      $('#synchronization-spinner').addClass('hidden')
      return

  checkSynchronization = ->
    return if $.cookie('async_synchronizations') == null
    $('#synchronization-spinner').removeClass('hidden')

    $.each JSON.parse($.cookie('async_synchronizations')), (index, synchronization) ->
      $.ajax(
        url: "/synchronizations/#{synchronization['mailing_list_id']}",
        success: (data) ->
          return if data['status'] != 200
      )

  bind = ->
    $(document).ready ->
      checkSynchronization()

  new AsyncSynchronizations
