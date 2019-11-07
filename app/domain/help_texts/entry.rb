# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::Entry
  attr_reader :key, :actions, :controller_name, :model_class

  def self.key(controller_name, model_class)
    [controller_name, model_class.to_s.underscore].compact.join('--')
  end

  def initialize(controller_name, model_class)
    @controller_name = controller_name
    @model_class     = model_class
    @key             = self.class.key(controller_name, model_class)

    @actions = []
  end

  def to_s
    model_class.model_name.human
  end

  def grouped
    %w(action field).collect do |kind|
      list  = send("#{kind}s_with_labels")
      label = HelpText.human_attribute_name("#{kind}", count: 2)

      OpenStruct.new(label: label, list: list)
    end
  end

  def actions_with_labels
    @actions_with_labels ||= with_labels(actions, %w(index edit new)) do |action|
      ["action.#{action}", translate_action(action)]
    end
  end

  def fields_with_labels
    @fields_with_labels ||= with_labels(fields) do |field|
      ["field.#{field}", translate_field(field)]
    end
  end

  def translate(kind, name)
    [HelpText.human_attribute_name("#{kind}"), send("translate_#{kind}", name)].join(' ')
  end

  def present?
    [actions_with_labels, fields_with_labels].any?(&:present?)
  end

  def fields
    used_attributes + permitted_attributes
  end

  private

  def used_attributes
    model_class.try(:used_attributes) || []
  end

  def permitted_attributes
    Array.wrap(controller_class.try(:permitted_attrs)).collect do |key|
      key.is_a?(Hash) ? key.keys.first : key
    end
  end

  def with_labels(list, whitelist = nil)
    list.collect do |key, _|
      yield key unless whitelist.present? && !whitelist.include?(key)
    end.compact.sort_by(&:second)
  end

  def translate_action(action, mapping = { index: :list, new: :add })
    I18n.t("global.link.#{mapping.fetch(action.to_sym, action)}")
  end

  def translate_field(field)
    model_class.human_attribute_name(field)
  end

  def controller_class
    @controller_class ||= "#{@controller_name}_controller".classify.constantize
  end

end


