# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::Entry
  attr_reader :key, :action_names, :existing, :controller_name, :model_class

  def self.key(controller_name, model_class)
    [controller_name, model_class.to_s.underscore].compact.join('--')
  end

  def initialize(controller_name, model_class, existing = nil)
    @controller_name = controller_name
    @model_class     = model_class
    @existing        = existing || { action: [], field: [] }
    @key             = self.class.key(controller_name, model_class)

    @action_names = []
  end

  def to_s
    model_class.model_name.human
  end

  def grouped
    %w(action field).collect do |kind|
      label = HelpText.human_attribute_name("#{kind}", count: 2)
      list  = labeled_list(kind)

      OpenStruct.new(label: label, list: list)
    end
  end

  def present?
    actions.present?
  end

  def translate(kind, name)
    format('%s "%s"', HelpText.human_attribute_name("#{kind}"), send("translate_#{kind}", name))
  end

  def fields
    (used_attributes + permitted_attributes).uniq.collect(&:to_s) - existing[:field] - blacklist
  end

  def actions
    (action_names & %w(index new edit show)) - existing[:action]
  end

  def labeled_list(kind)
    send(kind.to_s.pluralize).collect do |name, _|
      ["#{kind}.#{name}", send("translate_#{kind}", name)]
    end.compact.sort_by(&:second)
  end

  private

  def blacklist
    Settings.help_text_blacklist.to_h.fetch(model_class.base_class.to_s.underscore.to_sym, [])
  end

  def used_attributes
    model_class.try(:used_attributes) || []
  end

  def permitted_attributes
    Array.wrap(controller_class.try(:permitted_attrs)).collect do |key|
      key.is_a?(Hash) ? key.keys.first : key
    end
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


