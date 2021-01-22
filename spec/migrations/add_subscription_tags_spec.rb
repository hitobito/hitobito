# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
migration_file_name = Dir[Rails.root.join('db/migrate/20210114074037_add_subscription_tags.rb')].first
require migration_file_name


describe AddSubscriptionTags do

  before(:all) { self.use_transactional_tests = false }
  after(:all)  { self.use_transactional_tests = true }
  
  let(:migration) { described_class.new }
  let(:subscription) { subscriptions(:leaders_group) }
  let!(:email_primary_invalid) { PersonTags::Validation.email_primary_invalid(create: true) } 
  let!(:email_additional_invalid) { PersonTags::Validation.email_additional_invalid(create: true) } 

  after do
    SubscriptionTag.find_each { |subscription_tag| subscription_tag.delete }
    ActsAsTaggableOn::Tagging.find_each { |tagging| tagging.delete }
    ActsAsTaggableOn::Tag.find_each { |tag| tag.delete }
  end

  context '#up' do
    before do
      migration.down
    end

    it 'creates subscription_tags for each subscription tagging' do
      ActsAsTaggableOn::Tagging.create!(taggable_id: subscription.id,
                                        taggable_type: Subscription.sti_name,
                                        tag_id: email_primary_invalid.id,
                                        context: 'tags')
      ActsAsTaggableOn::Tagging.create!(taggable_id: subscription.id,
                                        taggable_type: Subscription.sti_name,
                                        tag_id: email_additional_invalid.id,
                                        context: 'tags')

      expect(ActsAsTaggableOn::Tagging.count).to eq(2)

      expect do
        migration.up
      end.to change { ActsAsTaggableOn::Tagging.count }.by(-2)

      expect(subscription.subscription_tags.count).to eq(2)
      expect(SubscriptionTag.where(subscription: subscription, tag: email_primary_invalid)).to exist
      expect(SubscriptionTag.where(subscription: subscription, tag: email_additional_invalid)).to exist
    end
  end

  context '#down' do
    after do
      migration.up
    end
    
    it 'creates subscription taggings for each subscription_tag' do
      SubscriptionTag.create!(subscription: subscription,
                              tag: email_primary_invalid)
      SubscriptionTag.create!(subscription: subscription,
                              tag: email_additional_invalid)
      expect(SubscriptionTag.count).to eq(2)

      expect do
        migration.down
      end.to change { ActsAsTaggableOn::Tagging.count }.by(2)

      expect(ActsAsTaggableOn::Tagging.where(taggable_id: subscription.id,
                                             taggable_type: Subscription.sti_name).count).to eq(2)
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: subscription.id,
                                             taggable_type: Subscription.sti_name,
                                             tag_id: email_primary_invalid.id)).to exist
      expect(ActsAsTaggableOn::Tagging.where(taggable_id: subscription.id,
                                             taggable_type: Subscription.sti_name,
                                             tag_id: email_additional_invalid.id)).to exist
    end
  end
end
