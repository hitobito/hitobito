# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Qualifications::List do
  let(:person) { Fabricate.build(:person) }

  let(:sl) { qualification_kinds(:sl) }
  let(:sl_leader) { qualification_kinds(:sl_leader) }
  let(:gl_leader) { qualification_kinds(:gl_leader) }

  subject(:list) { described_class.new(person) }

  describe '#qualifications' do
    it 'loads qualifications with kinds ordered by date' do
      expect(person).to receive_message_chain(:qualifications, :order_by_date, { includes: :qualification_kind })
        .and_return([])
      expect(list.qualifications).to be_empty
    end

    it 'marks first if of kind if it is reactivateable' do
      allow(list).to receive(:load_qualifications).and_return([
        Qualification.new(qualification_kind: sl_leader),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
    end

    it 'does not mark second of kind' do
      allow(list).to receive(:load_qualifications).and_return([
        Qualification.new(qualification_kind: sl_leader),
        Qualification.new(qualification_kind: sl_leader),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does mark first of kind qualification is active' do
      allow(list).to receive(:load_qualifications).and_return([
        Qualification.new(qualification_kind: sl, finish_at: 2.years.from_now.to_date),
        Qualification.new(qualification_kind: sl, finish_at: 1.years.from_now.to_date),
      ])
      expect(list.qualifications[0]).to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end

    it 'does not mark first of kind if qualification is inactive and not reactivateable' do
      allow(list).to receive(:load_qualifications).and_return([
        Qualification.new(qualification_kind: sl, finish_at: 1.years.ago.to_date),
        Qualification.new(qualification_kind: sl, finish_at: 2.years.ago.to_date),
      ])
      expect(list.qualifications[0]).not_to be_first_reactivateable
      expect(list.qualifications[1]).not_to be_first_reactivateable
    end
  end
end
