#  Copyright (c) 2012-2024, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Filter::AttributeControl < Filter::AttributeControl # rubocop:disable Rails/HelperInstanceVariable
  def initialize(template, event_type, attr, count, html_options = {})
    @event_type = event_type
    super(template, attr, count, html_options)
  end

  def model_class
    @event_type
  end
end
