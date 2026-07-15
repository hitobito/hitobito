# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Group::Statistics::Base
  include ActiveModel::Model

  # Unique key, MUST be set by subclasses
  class_attribute :key

  # Configure whether the statistic is only available for layer groups (default: true)
  class_attribute :layer_only, default: true
  # Statistic is available for the listed group types (all groups if empty)
  class_attribute :group_types, default: []

  # Permitted filter params (analogous to CrudController)
  class_attribute :permitted_params, default: []

  class << self
    # I18n key for the title
    def label_key
      "group.statistics.#{key}.title"
    end

    # Is this statistic available for the given group?
    def available_for?(group)
      # Check layer restriction if set
      return false if layer_only && !group.layer?

      # If group_types is empty, available for all groups
      return true if group_types.empty?

      # Otherwise only for specified group types
      group_types.any? { |type| group.is_a?(type) }
    end
  end

  def initialize(group, params = {})
    raise ArgumentError, "#{group} should be a layer" if self.class.layer_only && !group.layer?

    @group = group
    @layer = group.layer_group
    # Re-wrap params so we can call it with either ActionController::Parameters or a plain Hash
    @params = ActionController::Parameters.new(params.try(:to_unsafe_hash) || params)
  end

  attr_reader :group, :layer, :params

  # Path to the view partial
  def partial_path
    "group/statistics/#{self.class.key}"
  end

  # Filter params based on permitted_params (analogous to CrudController)
  def filter_params
    @filter_params ||= params.permit(*self.class.permitted_params).to_h.symbolize_keys
  end

  def parse_date(value)
    return nil if value.blank?
    Date.parse(value)
  rescue Date::Error, TypeError
    nil
  end
end
