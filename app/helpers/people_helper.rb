module PeopleHelper

  def format_gender(person)
    gender_label(person.gender)
  end
  
  def gender_label(gender)
    t("activerecord.attributes.person.genders.#{gender.presence || 'default'}")
  end

  # conditionally render event/application aside, maybe expand this to also include roles
  def render_event_aside(method)
    collection = entry.send(method)
    return unless collection.present?
    title = method == :pending_applications  ? "Anmeldungen" : "Events"
    data_role = method == :pending_applications  ? :applications : :upcoming
    render 'event_aside', collection: collection, title: title, data_role: data_role
  end

end
