#  Copyright (c) 2012-2024, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class Event::ParticipationContactData
  attr_reader :person

  class_attribute :mandatory_contact_attrs,
    :contact_attrs,
    :contact_associations

  self.mandatory_contact_attrs = [:email, :first_name, :last_name]

  self.contact_attrs = [:first_name, :last_name, :nickname, :company_name, :email,
    :address_care_of, :street, :housenumber, :postbox,
    :zip_code, :town,
    :country, :gender, :birthday, :phone_numbers, :language]

  if FeatureGate.disabled?("structured_addresses")
    contact_attrs.delete(:address_care_of)
    contact_attrs.delete(:street)
    contact_attrs.delete(:housenumber)
    contact_attrs.delete(:postbox)

    if FeatureGate.disabled?("address_migration")
      contact_attrs << :address
    end
  end
  if FeatureGate.enabled?("address_migration")
    contact_attrs.delete(:address_care_of)
    contact_attrs.delete(:street)
    contact_attrs.delete(:housenumber)
    contact_attrs.delete(:postbox)
  end

  self.contact_associations = [:additional_emails, :social_accounts]

  delegate(*contact_attrs, to: :person)
  delegate(*contact_associations, to: :person)

  delegate :t, to: I18n

  delegate :gender_label, :column_for_attribute, :timeliness_cache_attribute,
    :has_attribute?, to: :person

  delegate :layer_group, to: :event

  include ActiveModel::Validations

  validate :assert_required_contact_attrs_valid
  validate :assert_person_attrs_valid

  class << self
    delegate :reflect_on_association, :human_attribute_name, to: Person

    def base_class
      self
    end

    def demodulized_route_keys
      nil
    end
  end

  def initialize(event, person, model_params = {})
    @model_params = model_params
    @event = event
    @person = person
    person.attributes = model_params if model_params.present?
  end

  def save
    valid? && person.save
  end

  def parent
    event
  end

  def method_missing(method)
    return person.send(method) if /^.*_came_from_user\?/.match?(method)
    return person.send(method) if /^.*_before_type_cast/.match?(method)
    return person.send(method) if /^privacy_policy.*/.match?(method)

    super
  end

  def show_attr?(a)
    attribute_keys.include?(a)
  end

  def required_attr?(a)
    required_attrs.include?(a)
  end

  def attribute_keys
    self.class.contact_attrs - hidden_contact_attrs
  end

  def hidden_contact_attrs
    event.hidden_contact_attrs.collect(&:to_sym)
  end

  def respond_to?(attr, include_all = false)
    responds = super
    responds ? true : person.respond_to?(attr)
  end

  def new_record?
    true
  end

  def persisted?
    false
  end

  def to_model
    self
  end

  def to_key
    nil
  end

  def required_attrs
    @required_attrs ||= event.required_contact_attrs.map(&:to_sym) +
      self.class.mandatory_contact_attrs
  end

  private

  attr_reader :model_params, :event

  def assert_required_contact_attrs_valid
    required_attrs.each do |a|
      next assert_phone_number_present if a.to_sym == :phone_numbers

      if model_params[a].blank?
        errors.add(a, t("errors.messages.blank"))
      end
    end
  end

  def assert_phone_number_present
    phone_changes = {add: [], sub: []}
    changed_attrs = model_params.to_h.fetch("phone_numbers_attributes", {})

    phone_changes = changed_attrs.each_with_object(phone_changes) do |(_key, entry), memo|
      key = (entry["_destroy"] == "false") ? :add : :sub
      memo[key] << entry["number"]
    end

    if (phone_changes[:add] - phone_changes[:sub]).empty?
      errors.add("phone_numbers", t("errors.messages.blank"))
    end
  end

  def assert_person_attrs_valid
    unless person.valid?
      collect_person_errors
    end
  end

  def collect_person_errors
    person.errors.full_messages.each do |m|
      errors.add(:base, m)
    end
  end
end
