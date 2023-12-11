# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Used to generate static error pages with the application layout:
# RAILS_GROUPS=assets rails generate error_page {status}
#
# Can also be used for dynamic error pages if those static files do not exist.
class BlockedController < ApplicationController
  layout 'application'

  skip_authorization_check
  skip_before_action :reject_blocked_person!

  def index
    # @warn_after = Person::BlockService.warn? &&
    #                 distance_of_time_in_words(Person::BlockService.warn_after)
    # @block_after = Person::BlockService.block? &&
    #                 distance_of_time_in_words(Person::BlockService.block_after)

    render 'index', status: 403, formats: request.format.json? ? [:json] : [:html]
  end
end
