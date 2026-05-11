# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

namespace :cleanup do
  desc "Remove all people without active roles (deleted_people) in one go"
  task :deleted_people, [:group_id] => :environment do |t, args|
    target_groups = if args[:group_id].present?
      Group.where(id: args[:group_id])
    else
      Group.all
    end

    Group::DeletedPeople.deleted_for_multiple(target_groups).find_each do |person|
      People::Destroyer.new(person).run
    end
  end
end
