# encoding: utf-8

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PeopleHelper

  def format_gender(person)
    person.gender_label
  end

  def format_person_email(person)
    mail_to(person.email)
  end

  def format_person_login_status(person)
    icons = {
        no_login: 'user-slash',
        password_email_sent: 'user-clock',
        login: 'user-check',
        two_factors: 'user-shield'
    }
    status = person.login_status
    icon(
        icons.fetch(status),
        title: I18n.t("people.login_status.#{status}")
    )
  end

  def dropdown_people_export(details = false, emails = true, labels = true, households = true)
    Dropdown::PeopleExport.new(self, current_user, params, details: details,
                                                           emails: emails,
                                                           labels: labels,
                                                           households: households).to_s
  end

  def dropdown_people_login(person)
    Dropdown::PeopleLogin.new(self, person).to_s
  end

  def format_birthday(person)
    if person.birthday?
      f(person.birthday) << ' ' << t('people.years_old', years: person.years)
    end
  end

  def format_tags(person)
    if person.tags.present?
      person.tags.map(&:name).join(', ')
    else
      t('global.associations.no_entry')
    end
  end

  def sortable_grouped_person_attr(t, attrs, &block)
    list = attrs.map do |attr, sortable|
      if sortable
        t.sort_header(attr.to_sym, Person.human_attribute_name(attr.to_sym))
      else
        Person.human_attribute_name(attr.to_sym)
      end
    end

    header = list[0..-2].collect { |i| content_tag(:span, "#{i} |".html_safe, class: 'nowrap') }
    header << list.last
    t.col(safe_join(header, ' '), &block)
  end

  def send_login_tooltip_text
    entry.password? && t('.send_login_tooltip.reset') ||
      entry.reset_password_sent_at.present? && t('.send_login_tooltip.resend') ||
      t('.send_login_tooltip.new')
  end

  def person_link(person)
    person ? assoc_link(person) : "(#{t('global.nobody')})"
  end

  def format_person_layer_group(person)
    person.layer_group_label
  end

  def format_person_language(person)
    Person::LANGUAGES[person.language.to_sym]
  end

  def render_household(person)
    safe_join(person.household_people.collect do |p|
      content_tag(:li, class: 'chip') do
        can?(:show, p) ? link_to(p, p) : p.to_s
      end
    end, "\n")
  end

  def render_family(person)
    safe_join(person.family_members.map do |p|
      content_tag(:li, class: 'chip') do
        can?(:show, p) ? link_to(p, p) : p.to_s
      end
    end)
  end

  def may_impersonate?(user, group)
    can?(:impersonate_user, user) &&
      user != current_user &&
      !origin_user &&
      group.people.exists?(id: user.id)
  end

  def link_to_address(person)
    if [person.address, person.zip_code, person.town].all?(&:present?)
      link_to(icon('map-marker-alt', class: 'fa-2x'), person_address_url(person), target: '_blank')
    end
  end

  def person_address_url(person)
    query_params = { street: person.address,
                     postalcode: person.zip_code,
                     city: person.town,
                     country_codes: person.country }.to_query

    openstreetmap_url(query_params)
  end

  def openstreetmap_url(query_params)
    URI::HTTP.build(host: 'nominatim.openstreetmap.org',
                    path: '/search.php',
                    query: query_params).to_s
  end

  def upcoming_events_title
    title = [t('.events')]
    if entry.id == current_user.id
      title << link_to(icon(:'calendar-alt'), event_feed_path, title: t('event_feeds.integrate'))
    end
    safe_join(title, ' ')
  end

  def person_event_feed_url
    event_feed_url(token: current_user.event_feed_token, format: :ics)
  end

  def oneline_address(message)
    address = message.message_recipients.find_by(person_id: @person.id).address
    address.to_s.split("\n").join(', ')
  end

  def person_otp_qr_code(person, secret)
    qr_code = People::OneTimePassword.new(secret, person: person).provisioning_qr_code
    base64_data = Base64.encode64(qr_code.to_blob)
    "data:image/png;base64,#{base64_data}"
  end
end
