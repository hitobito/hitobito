# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

require "spec_helper"

describe QualificationDecorator do
  let(:kind) { Fabricate(:qualification_kind, required_training_days: 3) }
  let(:qualification) { Fabricate.build(:qualification, qualification_kind: kind, start_at: (0..24).to_a.sample.months.ago) }

  subject(:info) { qualification.decorate.open_training_days_info }

  subject(:dom) { Capybara::Node::Simple.new(info) }

  subject(:tooltip) { info[/title="(.*?)"/, 1] }

  let(:now) { Time.zone.local(2024, 3, 22, 15, 30) }

  around { |example| travel_to(now) { example.run } }

  context "without training days" do
    it "is nil if qualification is active" do
      expect(qualification).to be_active
      expect(info).to be_nil
    end

    it "has icon with tooltip but no days count when expired and not reactivateable" do
      qualification.finish_at = now - 1.day
      expect(qualification).not_to be_active
      expect(qualification).not_to be_reactivateable
      expect(dom).to have_css("span", count: 1)
      expect(tooltip).to eq "Diese Qualifikation ist seit dem 21.03.2024 abgelaufen. Falls du " \
                            "davor Aus- oder Fortbildungen besucht hast und du für diese eine Kursbestätigung " \
                            "besitzt, kannst du diese mit deinem Tourenchef teilen. Allenfalls kann dies zu einer " \
                            "Reaktivierung deiner bereits abgelaufenen Qualifikation führen."
    end
  end

  context "with training days" do
    before { qualification.open_training_days = 1.5 }

    it "contains days and icon but no tooltip when is active and does not expire" do
      expect(qualification).to be_active
      expect(tooltip).to be_blank
      expect(dom).to have_css("span", text: "1.5")
      expect(dom).to have_css "i.fas.fa-info-circle"
    end

    it "includes open days with icon informing about expiry" do
      qualification.finish_at = now + 1.day
      expect(qualification).to be_active
      expect(dom).to have_css("span", text: "1.5")
      expect(dom).to have_css "i.fas.fa-info-circle"
      expect(tooltip).to eq "Damit die Qualifikation am 23.03.2024 nicht abläuft, bitten wir " \
                            "dich bis dahin 1.5 Fortbildungstage zu absolvieren"
    end

    it "includes open training days with icon informing about how to reactivate" do
      qualification.qualification_kind = qualification_kinds(:sl_leader)
      qualification.finish_at = now - 1.day
      expect(qualification).to be_reactivateable
      expect(dom).to have_css "i.fas.fa-info-circle"
      expect(tooltip).to eq "Um deine Qualifikation zu reaktivieren, bitten wir dich 1.5 " \
                            "Fortbildungstage bis spätestens 21.03.2028 zu absolvieren"
    end
  end
end
