# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Wizards::Step do
  before do
    stub_const('One', Class.new(Wizards::Step))
    stub_const('Wizard', Class.new(Wizards::Base))
  end

  let(:wizard) { Wizard.new(current_step: 0) }
  subject(:step) { One.new(wizard) }

  describe '#partial' do
    subject(:partial) { step.partial }

    it 'is derived from class name' do
      expect(partial).to eq 'one'
    end

    it 'is read from class variable' do
      step.class.partial = :class_var
      expect(partial).to eq :class_var
    end

    it 'is read from instance method' do
      step.class.partial = :class_var
      expect(step).to receive(:partial).and_return(:method)
      expect(partial).to eq :method
    end
  end
end
