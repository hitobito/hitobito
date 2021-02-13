class Person::Filter::TagAbsence < Person::Filter::Tag
  def apply(scope)
    scope.where.not(people: {id: tagged_people_ids}).distinct
  end

  private

  def tagged_people_ids
    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .where(taggable_type: Person.to_s)
      .where(tags_condition)
      .select("DISTINCT taggable_id")
  end
end
