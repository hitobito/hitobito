#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddSubscriptionTags < ActiveRecord::Migration[6.0]
  def up
    create_table :subscription_tags do |t|
      t.boolean :excluded, default: false

      t.references :subscription, foreign_key: true, type: :integer, null: false
      t.references :tag, foreign_key: true, type: :integer, null: false
    end

    Subscription.groups.find_each do |subscription|
      taggings = ActsAsTaggableOn::Tagging.where(taggable_id: subscription.id,
                                                taggable_type: Subscription.sti_name)
      next unless taggings.present?
      taggings.find_each do |tagging|
        SubscriptionTag.create!(subscription_id: subscription.id, tag_id: tagging.tag_id)
        tagging.delete
      end
    end
  end

  def down
    SubscriptionTag.included.find_each do |subscription_tag|
      subscription = subscription_tag.subscription
      ActsAsTaggableOn::Tagging.create!(taggable_id: subscription.id,
                                        taggable_type: Subscription.sti_name,
                                        tag_id: subscription_tag.tag_id,
                                        context: 'tags')
    end

    drop_table :subscription_tags
  end
end

