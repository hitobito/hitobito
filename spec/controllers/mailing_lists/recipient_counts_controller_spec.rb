# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailingLists::RecipientCountsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:mailing_list) { mailing_lists(:top_group) }

  before { sign_in(top_leader) }

  context 'GET index' do
    render_views

    context 'letter with people' do

      before do
        fabricate_recipients(:subscription_with_subscriber_with_address, 20)
        fabricate_recipients(:subscription, 10)
      end

      it 'returns count' do
        get :index, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id, message_type: 'Message::Letter', message: { send_to_households: false }, format: :js }, xhr: true

        expect(response.body).to match('Brief wird für 20 Personen erstellt.')
        expect(response.body).to match('10 weitere haben keine vollständige Adresse hinterlegt.')
      end
    end

    context 'letter with households' do

      before do
        fabricate_recipients(:subscription_with_subscriber_with_address, 5)
        fabricate_valid_households(10)
        fabricate_recipients(:subscription, 10)
      end

      it 'returns count' do
        get :index, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id, message_type: 'Message::Letter', message: { send_to_households: true }, format: :js }, xhr: true

        expect(response.body).to match('Brief wird für 15 Haushalte erstellt.')
        expect(response.body).to match('10 weitere haben keine vollständige Adresse hinterlegt.')
      end
    end

    context 'letter_with_invoice with people' do

      before do
        fabricate_recipients(:subscription_with_subscriber_with_address, 20)
        fabricate_recipients(:subscription, 10)
      end

      it 'returns count' do
        get :index, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id, message_type: 'Message::LetterWithInvoice', message: { send_to_households: false }, format: :js }, xhr: true

        expect(response.body).to match('Rechnungsbrief wird für 20 Personen erstellt.')
        expect(response.body).to match('10 weitere haben keine vollständige Adresse hinterlegt.')
      end
    end

    context 'text_message with people' do

      before do
        fabricate_recipients(:subscription_with_subscriber_with_phone, 20)
        fabricate_recipients(:subscription, 10)
      end

      it 'returns count' do
        get :index, params: { group_id: mailing_list.group.id, mailing_list_id: mailing_list.id, message_type: 'Message::TextMessage', format: :js }, xhr: true

        expect(response.body).to match('SMS wird für 20 Personen erstellt.')
        expect(response.body).to match('10 weitere haben keine Mobiltelefonnummer hinterlegt.')
      end
    end
  end

  private

  def fabricate_recipients(fabricator, num = 1)
    Fabricate.times(num, fabricator, mailing_list: mailing_list).
        map(&:subscriber).
        tap do |people|
          people.each { |person| Fabricate(:'Group::TopGroup::Member', person: person, group: mailing_list.group) }
        end
  end

  def fabricate_valid_households(num = 1)
    num.times do
      household_key = Person::Household.new(nil, nil, nil, nil).send(:next_key)

      # between 2 and 6 housemates
      housemates = fabricate_recipients(:subscription_with_subscriber_with_address, 2 + rand(4))
      housemates.each {|housemate| housemate.update_attribute(:household_key, household_key) }
    end
  end
end
