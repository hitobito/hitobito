#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TableDisplays::People
  class LoginStatusColumn < TableDisplays::Column

    def required_permission(attr)
      :show
    end

    def required_model_attrs(attr)
      %w(people.two_factor_authentication people.email people.encrypted_password
         people.reset_password_sent_at people.contact_data_visible)
    end

    def render(attr)
      super do |target, target_attr|
        template.format_attr(target, target_attr) if target.respond_to?(target_attr)
      end
    end

    def sort_by(attr)
      nil
    end
  end
end
