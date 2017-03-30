# encoding: utf-8

#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class Event::ParticipationContactData

  attr_reader :person

  T_PERSON_ATTRS = 'activerecord.attributes.person.'.freeze

  # rubocop:disable Style/MutableConstant
  MANDATORY_CONTACT_ATTRS = [:email, :first_name, :last_name]

  CONTACT_ATTRS = [:first_name, :last_name, :nickname, :company_name,
                   :email, :address, :zip_code, :town,
                   :country, :gender, :birthday]

  CONTACT_ASSOCIATIONS = [:additional_emails, :phone_numbers, :social_accounts]
  # rubocop:enable Style/MutableConstant

  delegate(*CONTACT_ATTRS, to: :person)
  delegate(*CONTACT_ASSOCIATIONS, to: :person)

  delegate :t, to: I18n

  delegate :gender_label, :column_for_attribute, :timeliness_cache_attribute,
           :has_attribute?, to: :person

  delegate :layer_group, to: :event

  include ActiveModel::Validations

  validate :validate_required_contact_attrs
  validate :validate_person_attrs

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
    return false unless valid?
    person.save
  end

  def parent
    event
  end

  def method_missing(method)
    return person.send(method) if method =~ /^.*_came_from_user\?/
    return person.send(method) if method =~ /^.*_before_type_cast/

    super(method)
  end

  def show_attr?(a)
    attribute_keys.include?(a)
  end

  def required_attr?(a)
    required_attributes.include?(a.to_s)
  end

  def attribute_keys
    CONTACT_ATTRS - hidden_contact_attrs
  end

  def hidden_contact_attrs
    event.hidden_contact_attrs.collect(&:to_sym)
  end

  def respond_to?(attr)
    responds = super(attr)
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

  def required_attributes
    @required_attributes ||= event.required_contact_attrs +
      MANDATORY_CONTACT_ATTRS.map(&:to_s)
  end

  private

  attr_reader :model_params, :event

  def validate_required_contact_attrs
    required_attributes.each do |a|
      if model_params[a.to_s].blank?
        errors.add(a, t('errors.messages.blank'))
      end
    end
  end

  def validate_person_attrs
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
