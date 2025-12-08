# frozen_string_literal: true

module TagsForSubscriptionTags
  extend ActiveSupport::Concern

  included do
    # needed so tags can be destroyed even when they are referenced by a SubscriptionTag
    has_many :subscription_tags, dependent: :destroy
  end
end
