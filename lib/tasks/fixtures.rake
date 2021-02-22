# frozen_string_literal: true

#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :fixtures do
  desc "Export groups suitable for fixtures"
  task groups: [:environment] do
    data = {}

    fixture_id = lambda { |group|
      return nil unless group
      return "root" if group.id == 1 && group.parent_id.nil?

      parts = if Group.where(name: group.name).one?
        [group.display_name.parameterize]
      else
        [group.display_name.parameterize, group.id]
      end

      parts.join("-").tr("-", "_")
    }

    fixture_data = [:lft, :rgt, :name, :short_name, :type, :email, :address, :zip_code, :town]

    Group.order(:lft).find_each do |group|
      entry = {
        "parent" => fixture_id[group.parent],
        "layer_group_id" =>
          "<%=ActiveRecord::FixtureSet.identify(:#{fixture_id[group.layer_group]})%>",
      }

      fixture_data.each do |field|
        entry[field.to_s] = group.send(field) if group.send(field).present?
      end

      data[fixture_id[group]] = entry
    end

    puts YAML.dump(data)
  end
end
