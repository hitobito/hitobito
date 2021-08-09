# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte. This file is part of
#  hitobito_die_mitte and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_die_mitte.

require 'spec_helper'

describe Donation do
  let(:top_leader) { people(:top_leader) }
  let(:top_layer) { groups(:top_layer) }
  let(:bottom_member) { people(:bottom_member) }


  context 'in_last' do
    it 'does not allow current year' do
      expect do
        Donation.new.in_last(1.second)
      end.to raise_error('Has to be at least one year in the past')
    end
    
    it 'considers whole year' do
      fabricated_donation1 = fabricate_donation(50.0, Date.new(1.year.ago.year, 1, 1))
      fabricated_donation2 = fabricate_donation(50.0, Date.new(1.year.ago.year, 7, 20))
      fabricated_donation3 = fabricate_donation(50.0, Date.new(1.year.ago.year, 12, 31))

      donations = Donation.new.in_last(1.year).instance_variable_get(:@donations)

      expect(donations.size).to eq(3)
      expect(donations).to include(fabricated_donation1)
      expect(donations).to include(fabricated_donation2)
      expect(donations).to include(fabricated_donation3)
    end
    
    it 'considers multiple whole years' do
      fabricated_donation1 = fabricate_donation(50.0, Date.new(3.years.ago.year, 1, 1))
      fabricated_donation2 = fabricate_donation(50.0, Date.new(2.years.ago.year, 3, 20))
      fabricated_donation3 = fabricate_donation(50.0, Date.new(1.year.ago.year, 12, 31))

      donations = Donation.new.in_last(3.years).instance_variable_get(:@donations)

      expect(donations.size).to eq(3)
      expect(donations).to include(fabricated_donation1)
      expect(donations).to include(fabricated_donation2)
      expect(donations).to include(fabricated_donation3)
    end
    
    it 'does not find donation outside of duration' do
      fabricate_donation(50.0, Date.new(2.year.ago.year, 3, 20))

      donations = Donation.new.in_last(1.year).instance_variable_get(:@donations)

      expect(donations).to be_empty
    end
  end

  context 'previous_amount' do
    context 'previous_amount below 100' do
      it 'calculates increased amount' do
        fabricate_donation(50.0)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 10)

        expect(increased_amount).to eq(55)
      end

      it 'calculates increased amount and rounds up to 5' do
        fabricate_donation(50)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        # 52.5 gets round up to 55
        expect(increased_amount).to eq(55)
      end

      it 'calculates increased amount and rounds down to 5' do
        fabricate_donation(50)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 4)

        # 52 gets round down to 50
        expect(increased_amount).to eq(50)
      end
    end

    context 'previous_amount below 1000' do
      it 'calculates increased amount' do
        fabricate_donation(100)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 10)

        expect(increased_amount).to eq(110)
      end

      it 'calculates increased amount and rounds up to 10' do
        fabricate_donation(100)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        # 105 gets round up to 110
        expect(increased_amount).to eq(110)
      end

      it 'calculates increased amount and rounds down to 10' do
        fabricate_donation(100)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 4)

        # 104 gets round down to 100
        expect(increased_amount).to eq(100)
      end
    end

    context 'previous_amount above 1000' do
      it 'calculates increased amount' do
        fabricate_donation(1000)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 5)

        expect(increased_amount).to eq(1050)
      end

      it 'calculates increased amount and rounds up to 50' do
        fabricate_donation(1000)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 13)

        # 1130 gets round up to 1150
        expect(increased_amount).to eq(1150)
      end

      it 'calculates increased amount and rounds down to 50' do
        fabricate_donation(1000)

        increased_amount = Donation.new.in_last(1.year).in_layer(top_layer).of_person(bottom_member).previous_amount(increased_by: 12)

        # 1120 gets round down to 1100
        expect(increased_amount).to eq(1100)
      end
    end
  end

  private

  def fabricate_donation(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: top_leader, recipient: bottom_member, group: top_layer, state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end

end

