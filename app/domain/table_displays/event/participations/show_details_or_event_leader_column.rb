#  Copyright (c) 2023, Cevi Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays::Event::Participations
  class ShowDetailsOrEventLeaderColumn < TableDisplays::PublicColumn

    protected

    def allowed?(object, _attr, original_object, _original_attr)
      event_leader?(original_object) || show_details?(object)
    end

    private

    def show_details?(person)
      ability.can?(:show_details, person)
    end

    def event_leader?(event)
      ability.can?(:update, event)
    end
  end
end
