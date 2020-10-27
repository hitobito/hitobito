class TagList

  def initialize(people, tags)
    @people = people
    @tags = tags
  end

  def add
    ActiveRecord::Base.transaction do
      @people.sum do |person|
        add_to_person(person)
      end
    end
  end

  def remove
    tags = ActsAsTaggableOn::Tagging.where(taggable_type: Person.name,
                                           taggable_id: @people.map(&:id),
                                           tag_id: @tags.map(&:id))
    tags.destroy_all.count
  end

  private

  def add_to_person(person)
    tags = @tags - person.tags
    person.tag_list.add(tags)
    person.save ? tags.count : 0
  end
end
