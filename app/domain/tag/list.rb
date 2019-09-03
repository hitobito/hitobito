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
      ActiveRecord::Base.transaction do
        new_tags[:hash].each do |person, tags|
          person.tag_list.add(tags)
          new_tags[:count] -= tags.count unless person.save
        end
      end
      new_tags[:count]
    end

    def remove
      tags = ActsAsTaggableOn::Tagging.where(taggable_type: Person.name,
                                             taggable_id: @people.map(&:id),
                                             tag_id: @tags.map(&:id))
      tags.destroy_all.count
    end

    private

    def build_new_tags
      new_tags = @people.map do |person|
        [person, @tags - person.tags]
      end
      { hash: new_tags.to_h, count: new_tags.sum { |e| e[1].count } }
    end
  end
end
