# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require 'spec_helper'

describe Export::Tabular::Base do
  let(:tabular) do
    Class.new(Export::Tabular::Base) do
      self.model_class = ::Person

      def attributes = %i[first_name]
    end
  end

  subject(:instance) { tabular.new(Person.where(id: people(:top_leader))) }

  describe '#attribute_labels' do
    it 'gets attribute labels from instance methods' do
      instance.define_singleton_method(:first_name_label) { 'Taufname' }
      expect(instance.attribute_labels).to eq(first_name: 'Taufname')
    end

    it 'falls back to human attribute name if no label method is present' do
      expect(instance).not_to respond_to("first_name_label")
      expect(instance.attribute_labels).to eq(first_name: 'Vorname')
    end
  end

end
