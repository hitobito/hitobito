# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Import
  class ContactAccountFields < SimpleDelegator
    attr_reader :prefix, :human

    def initialize(model)
      @prefix = model.model_name.to_s.underscore
      @human = model.model_name.human
      @model = model

      super(map_prefined_fields.with_indifferent_access)
    end

    def fields
      map { |key, value|  { key: key, value: value }  }
    end

    def key_for(label)
      "#{prefix}_#{label}".downcase
    end

    private

    def map_prefined_fields
      predefined_labels.each_with_object({}) do |label, hash|
        hash[key_for(label).downcase] = "#{human} #{@model.translate_label(label)}"
      end
    end

    def predefined_labels
      Settings.send(prefix).predefined_labels
    end
  end
end
