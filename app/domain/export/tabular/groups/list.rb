# frozen_string_literal: true

#  Copyright (c) 2014-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::Groups
  class List < Export::Tabular::Base

    EXCLUDED_ATTRS = %w(lft rgt contact_id require_person_add_requests logo
                        created_at deleted_at archived_at
                        creator_id updater_id deleter_id self_registration_role_type
                        self_registration_notification_email).freeze

    self.model_class = Group
    self.row_class = Export::Tabular::Groups::Row

    def attributes
      attrs = model_class.column_names + [:phone_numbers, :member_count, :social_accounts]
      (attrs - EXCLUDED_ATTRS).collect(&:to_sym)
    end

  end
end
