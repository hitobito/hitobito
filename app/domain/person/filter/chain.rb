# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Chain

  TYPES = [ # rubocop:disable Style/MutableConstant
    Person::Filter::Role,
    Person::Filter::Qualification
  ]

  # Used for `serialize` method in ActiveRecord
  class << self
    def load(yaml)
      new(YAML.load(yaml || ''))
    end

    def dump(obj)
      unless obj.is_a?(self)
        raise ::ActiveRecord::SerializationTypeMismatch,
              "Attribute was supposed to be a #{self}, but was a #{obj.class}. -- #{obj.inspect}"
      end

      YAML.dump(obj.to_hash)
    end
  end

  attr_reader :filters

  def initialize(params)
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

  def to_hash
    # call #to_hash twice to get a regular hash (without indifferent access)
    filters.each_with_object({}) { |f, h| h[f.attr.to_s] = f.to_hash.to_hash }
  end

  def to_params
    to_hash
  end

  def required_abilities
    filters.map(&:required_ability).uniq
  end

  private

  def parse(params)
    (params || {}).map { |attr, args| build_filter(attr, args) }.compact
  end

  def build_filter(attr, args)
    filter = filter_type(attr).new(attr, args.with_indifferent_access)
    filter.present? ? filter : nil
  end

  def filter_type(attr)
    key = filter_type_key(attr)
    TYPES.find { |t| t.key == key } ||
      raise(ArgumentError, "Unknown filter type #{key}")
  end

  def filter_type_key(attr)
    # TODO: map filter types for regular person attrs
    attr.to_s
  end

end
