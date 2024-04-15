# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require 'spec_helper'

describe QualificationDecorator do
  let(:qualification) { Fabricate.build(:qualification) }

  subject(:open_training_days) { qualification.decorate.open_training_days }
  subject(:open_training_days_dom) { Capybara::Node::Simple.new(open_training_days) }
  subject(:tooltip) { open_training_days[/title="(.*)"/,1] }
  let(:now) { Date.new(2024, 3, 22) }

  it 'is blank when no training days are set on model' do
    expect(open_training_days).to be_blank
  end

  context 'with training days' do
    before { qualification.open_training_days = 1.5 }
    around { |example| travel_to(now) { example.run } }

    it 'returns formatted training days with icon' do
      expect(open_training_days).to have_text '1.5'
      expect(open_training_days_dom).to have_css 'i.fas.fa-info-circle.p-1'
    end

    it 'has no tooltip for active qualification without finish_at' do
      expect(qualification).to be_active
      expect(open_training_days).not_to have_css 'span[title]'
    end

    it 'has tooltip for active qualification with finish_at' do
      qualification.finish_at = now + 1.day
      expect(qualification).to be_active
      expect(tooltip).to eq 'Damit die Qualifikation am 23.03.2024 nicht abläuft, bitten wir ' \
        'dich 1.5 Fortbildungstage zu absolvieren'
    end

    it 'has tooltip for reactivateable' do
      qualification.qualification_kind = qualification_kinds(:sl_leader)
      qualification.finish_at = now - 1.day
      expect(qualification).to be_reactivateable
      expect(tooltip).to eq 'Um deine Qualifikation zu reaktivieren, bitten wir dich 1.5 ' \
        'Fortbildungstage bis spätestens 21.03.2028 zu absolvieren'
    end
  end
end
