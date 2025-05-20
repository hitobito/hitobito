# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

# == Schema Information
#
# Table name: person_duplicates
#
#  id          :bigint           not null, primary key
#  ignore      :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  person_1_id :integer          not null
#  person_2_id :integer          not null
#
# Indexes
#
#  index_person_duplicates_on_person_1_id_and_person_2_id  (person_1_id,person_2_id) UNIQUE
#

require "spec_helper"

describe PersonDuplicate do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:duplicate) { PersonDuplicate.create!(person_1: top_leader, person_2: bottom_member) }

  it "assigns person with lower id to person_1" do
    expect(duplicate.person_1_id).to be < duplicate.person_2_id
    duplicate.update!(person_1: bottom_member, person_2: top_leader)
    expect(duplicate.person_1_id).to be < duplicate.person_2_id
  end

  context "validations" do
    it "is valid in base context" do
      expect(duplicate).to be_valid
    end

    it "is invalid in merge context when there is any possible invalid role when merging" do
      bottom_member.roles.first.update_columns(start_on: 10.days.ago, end_on: 20.days.ago)
      expect(duplicate).to be_valid

      expect(duplicate.valid?(context: :merge)).to be_falsey
      expect(duplicate.errors.full_messages).to eq ["Rolle Member (bis #{I18n.l(20.days.ago.to_date)}) von Bottom Member ist fürs Zusammenführen nicht gültig, da die andere Person eventuell bereits eine Rolle hat, welche diese Rolle nicht mehr erlaubt, diese muss manuell korrigiert/etnfernt werden. Info: Bis kann nicht vor Von sein"]
    end
  end
end
