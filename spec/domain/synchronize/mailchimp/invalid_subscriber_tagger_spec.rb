# frozen_string_literal: true

#  Copyright (c) 2012-2024, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require 'spec_helper'

describe Synchronize::Mailchimp::InvalidSubscriberTagger do
  let(:list) { mailing_lists(:leaders) }
  let(:person) { people(:top_leader) }

  before do
    Subscription.create!(mailing_list: list, subscriber: person)
  end

  it 'tags by primary email' do
    expect do
      Synchronize::Mailchimp::InvalidSubscriberTagger.new([person.email], list).tag!
    end.to change { person.tags.count }.by(1)

    expect(person.tags.map(&:name)).to include 'category_validation:email_primary_invalid'
  end

  it 'tags by secondary email' do
    AdditionalEmail.create!(
      email: 'foo@bar.com', contactable: person, label: 'Privat', mailings: true
    )
    list.update(mailchimp_include_additional_emails: true)

    expect do
      Synchronize::Mailchimp::InvalidSubscriberTagger.new(['foo@bar.com'], list).tag!
    end.to change { person.tags.count }.by(1)

    expect(person.tags.map(&:name)).to include 'category_validation:email_additional_invalid'
  end
end
