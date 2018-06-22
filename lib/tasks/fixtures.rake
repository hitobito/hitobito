# encoding: utf-8

#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :fixtures do
  desc 'Export groups suitable for fixtures'
  task groups: [:environment] do
    data = {}

    fixture_id = lambda { |group|
      [group.name.parameterize, group.id].join('-').tr('-', '_') if group
    }

    fixture_data = [:lft, :rgt, :name, :type, :email, :address, :zip_code, :town]

    Group.order(:lft).find_each do |group|
      entry = {
        'parent'         => fixture_id[group.parent],
        'layer_group_id' =>
          "<%=ActiveRecord::FixtureSet.identify(:#{fixture_id[group.layer_group]})%>"
      }

      fixture_data.each do |field|
        entry[field.to_s] = group.send(field) if group.send(field).present?
      end

      data[fixture_id[group]] = entry
    end

    puts YAML.dump(data)
  end
end
