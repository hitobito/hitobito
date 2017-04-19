#  Copyright (c) 2015 Pro Natura Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

app = window.App ||= {}

class app.ApplicationMarket
  updateCount: ->
    applications = $('tbody#applications tr').size()
    selector = if applications == 1 then 'one' else 'other'
    text = "#{applications} "
    text += $(".pending_applications_info .#{selector}").text()
    $('.pending_applications_info span:eq(0)').html(text)

  moveElementToBottom: (elementId, targetId, callback) ->
    $target = $('#' + targetId)
    left = $target.offset().left
    top = $target.offset().top + $target.height()
    $element = $('#' + elementId)
    leftOld = $element.offset().left
    topOld = $element.offset().top
    $element.children().each((i, c) -> $c = $(c); $c.css('width', $c.width()))
    $element.css('left', leftOld)
    $element.css('top', topOld)
    $element.css('position', 'absolute')
    $element.animate({left: left, top: top}, 300, callback)
