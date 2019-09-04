#  Copyright (c) 2019, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Tag
  class List

    def initialize(people, tags)
      @people = people
      @tags = tags
    end

    def add
      new_tags = build_new_tags
      count = 0
      ActiveRecord::Base.transaction do
        new_tags.each do |person, tags|
          person.tag_list.add(tags)
          count += tags.count if person.save
        end
      end
      count
    end

    def remove
      tags = ActsAsTaggableOn::Tagging.where(taggable_type: Person.name,
                                             taggable_id: @people.map(&:id),
                                             tag_id: @tags.map(&:id))
      tags.destroy_all.count
    end

    private

    def build_new_tags
      @people.map { |person| [person, @tags - person.tags] }.to_h
    end
  end
end
