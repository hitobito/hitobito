# frozen_string_literal: true

#  Copyright (c) 2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HelpTexts::Entry
  attr_reader :key, :fields, :actions, :model_class

  def self.key(controller_name, model_name)
    [controller_name, model_name.try(:underscore)].compact.join('--')
  end

  def initialize(controller_name, model_name)
    @controller_name = controller_name
    @model_class     = model_name.classify.constantize if model_name
    @key             = self.class.key(controller_name, model_name)

    @actions = []
    @fields  = []
  end

  def to_s
    model? ? model_class.model_name.human : @controller_name
  end

  def model?
    model_class.present?
  end

  def actions_with_labels
    actions.collect do |action|
      ["action.#{action}", HelpText.human_attribute_name("key.#{action}")]
    end
  end

  def fields_with_labels
    fields.collect do |field|
      ["field.#{field}", model_class.human_attribute_name(field)]
    end
  end

end

