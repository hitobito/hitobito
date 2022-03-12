# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module CalendarsHelper

  def event_type_options(layer)
    layer.event_types.map do |event_type|
      [event_type.model_name.human(count: 2), event_type.to_s]
    end
  end

end
