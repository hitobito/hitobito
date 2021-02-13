# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe AbilityDsl::Store do
  subject { AbilityDsl::Store.new }

  before { subject.load }

  context "#add" do
    it "storing config with the same key overrides the previous one" do
      c1 = AbilityDsl::Config.new(:perm, :subj, :action, :ability1, :constraint1)
      c2 = AbilityDsl::Config.new(:perm, :subj, :action, :ability1, :constraint2)
      c3 = AbilityDsl::Config.new(:perm, :subj, :action, :ability2, :constraint2)
      subject.add(c1)
      expect(subject.config(:perm, :subj, :action)).to eq(c1)
      subject.add(c2)
      expect(subject.config(:perm, :subj, :action)).to eq(c2)
      subject.add(c3)
      expect(subject.config(:perm, :subj, :action)).to eq(c3)
    end
  end

  context "#general_constraints" do
    it "retrieves general constraint for all and specific action" do
      c1 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, AbilityDsl::Recorder::General::ALL_ACTION, :ability1, :constraint1)
      c2 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, :action, :ability1, :constraint2)
      subject.add(c1)
      subject.add(c2)
      expect(subject.general_constraints(:subj, :action)).to match_array([c1, c2])
    end

    it "retrieves general constraint for all action" do
      c1 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, AbilityDsl::Recorder::General::ALL_ACTION, :ability1, :constraint1)
      c2 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, :action2, :ability1, :constraint2)
      subject.add(c1)
      subject.add(c2)
      expect(subject.general_constraints(:subj, :action)).to match_array([c1])
    end

    it "retrieves general constraint for specific action" do
      c1 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, :action, :ability1, :constraint1)
      c2 = AbilityDsl::Config.new(AbilityDsl::Recorder::General::PERMISSION, :subj, :action2, :ability1, :constraint2)
      subject.add(c1)
      subject.add(c2)
      expect(subject.general_constraints(:subj, :action)).to match_array([c1])
    end
  end
end
