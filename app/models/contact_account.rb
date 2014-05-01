# encoding: utf-8

#  Copyright (c) 2014 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactAccount
  extend ActiveSupport::Concern
  include NormalizedI18nLabels

  included do
    class_attribute :value_attr

    self.labels_translations_key = 'activerecord.attributes.contact_account.predefined_labels'

    has_paper_trail meta: { main: :contactable }

    belongs_to :contactable, polymorphic: true

    validates :label, presence: true
  end

  def to_s(_format = :default)
    "#{value} (#{label})"
  end

  def value
    send(value_attr)
  end
end
