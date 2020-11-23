# encoding: utf-8

#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

import Cookies from 'js-cookie'

app = window.App ||= {}

class app.AsyncSynchronizations

  constructor: () ->
    bind.call()
    setInterval(( -> checkSynchronizationCookie()), 500)
    setInterval(( -> checkSynchronization()), 3000)

  checkSynchronizationCookie = ->
    if Cookies.get('async_synchronizations') == undefined
      $('#synchronization-spinner').addClass('hidden')
      return

  checkSynchronization = ->
    return if Cookies.get('async_synchronizations') == undefined
    $('#synchronization-spinner').removeClass('hidden')

    $.each JSON.parse(Cookies.get('async_synchronizations')), (index, synchronization) ->
      $.ajax(
        url: "/synchronizations/#{synchronization['mailing_list_id']}",
        success: (data) ->
          return unless data['status'] == 422
          window.location.reload() # error condition
      )

  bind = ->
    $(document).ready ->
      checkSynchronization()

    $(document).on 'click', '#cancel_async_synchronizations', (e) ->
      Cookies.remove('async_synchronizations', { path: '/' })

  new AsyncSynchronizations
