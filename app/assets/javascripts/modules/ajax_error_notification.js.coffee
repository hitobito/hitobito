#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# show alert if ajax requests fail
$(document).on('ajax:error', (event, xhr, status, error) ->
  alert('Sorry, something went wrong\n(' + error + ')'))

