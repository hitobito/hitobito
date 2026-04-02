# frozen_string_literal: true

#  Copyright (c) 2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Events::Filter
  class Leader < Base
    self.permitted_args = [:ids, :user]

    def apply(scope)
      scope
        .joins(participations: :roles)
        .where(
          event_participations: {
            active: true,
            participant_id: leader_ids,
            participant_type: "Person"
          },
          event_roles: {
            type: leader_roles.map(&:sti_name)
          }
        )
    end

    def blank?
      leader_ids.blank?
    end

    private

    def leader_ids
      ids = Array(args[:ids]).compact_blank
      if args[:user].to_s == "1" && Auth.current_person
        ids << Auth.current_person.id
      end
      ids
    end

    def leader_roles
      event_types
        .flat_map { |type| type.role_types.select { |role| role.kind == :leader } }
        .uniq
    end
  end
end
