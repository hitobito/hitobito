# frozen_string_literal: true

#  Copyright (c) 2017 - 2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Chain
  TYPES = [ # rubocop:disable Style/MutableConstant these are meant to be extended in wagons
    Person::Filter::Role,
    Person::Filter::Qualification,
    Person::Filter::Attributes,
    Person::Filter::Language,
    Person::Filter::Tag,
    Person::Filter::TagAbsence
  ]

  # Used for `serialize` method in ActiveRecord
  class << self
    def load(yaml)
      obj = new(YAML.safe_load(yaml || ""))

      # This part is used to migrate the existing language filters to the attribute filters
      # Find language filter
      language_filter = find_filter_attr("language", obj)
      return obj unless language_filter

      # Prepare new entry of language values in attributes
      timestamp = (Time.now.to_f * 1000).to_i.to_s
      new_entry = {
        "key" => "language",
        "constraint" => "equal",
        "value" => language_filter.allowed_values
      }

      # Add to attributes filter or create new one
      attributes_filter = find_filter_attr("attributes", obj)
      if attributes_filter
        attributes_filter.args[timestamp] = new_entry
      else
        filter = Person::Filter::Attributes.new("attributes", {timestamp => new_entry})
        obj.filters << filter
      end

      # Remove original language filter
      obj.filters.reject! { |filter| filter.instance_variable_get(:@attr) == "language" }

      YAML.dump(obj.to_hash.deep_stringify_keys)
      obj
    end

    def dump(obj)
      unless obj.is_a?(self)
        raise ::ActiveRecord::SerializationTypeMismatch,
          "Attribute was supposed to be a #{self}, but was a #{obj.class}. -- #{obj.inspect}"
      end

      YAML.dump(obj.to_hash.deep_stringify_keys)
    end

    private

    def find_filter_attr(attr, chain)
      chain.filters.find do |filter|
        filter.instance_variable_get(:@attr) == attr
      end
    end
  end

  attr_reader :filters

  def initialize(params = nil)
    @filters = parse(params)
  end

  def filter(scope)
    filters.inject(scope) do |s, filter|
      filter.apply(s)
    end
  end

  def [](attr)
    filters.find { |f| f.attr == attr.to_s }
  end

  def blank?
    filters.blank?
  end

  def include_ended_roles?
    filters.any?(&:include_ended_roles?)
  end

  def roles_join
    first_custom_roles_join || {roles: :group}
  end

  def to_hash
    # call #to_hash twice to get a regular hash (without indifferent access)
    build_hash { |f| f.to_hash.to_hash }
  end

  def to_params
    build_hash { |f| f.to_params }
  end

  def required_abilities
    filters.map(&:required_ability).uniq
  end

  private

  def first_custom_roles_join
    filters.collect(&:roles_join).compact.first
  end

  def build_hash
    filters.each_with_object({}) { |f, h| h[f.attr] = yield f }
  end

  def parse(params)
    params = params.to_unsafe_h if params.is_a?(ActionController::Parameters)
    (params || {}).map { |attr, args| build_filter(attr, args) }.compact
  end

  def build_filter(attr, args)
    type = filter_type(attr)
    if type
      filter = type.new(attr, args.with_indifferent_access)
      filter.presence
    end
  end

  def filter_type(attr)
    key = filter_type_key(attr)
    self.class::TYPES.find { |t| t.key == key }
  end

  def filter_type_key(attr)
    # TODO: map filter types for regular person attrs
    attr.to_s
  end
end
