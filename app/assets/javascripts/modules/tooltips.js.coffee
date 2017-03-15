#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# only bind events for non-document elements in turbolinks:load
$(document).on('turbolinks:load', ->
  # wire up tooltips
  $(document).tooltip({ selector: '[rel^=tooltip]', placement: 'right' })
)
