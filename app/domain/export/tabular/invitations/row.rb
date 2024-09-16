# frozen_string_literal: true

#  Copyright (c) 2023-2023, Carbon. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Invitations
  class Row < Export::Tabular::Row
    def person
      entry.person
    end

    def mail
      entry.person.email if can?(:show, entry.person)
    end

    def participation_type
      entry.participation_type.constantize.model_name.human
    end

    def status
      I18n.t("activerecord.attributes.event/invitation.statuses.#{entry.status}")
    end

    def declined_at
      entry.declined_at
    end

    def created_at
      entry.created_at
    end
  end
end
