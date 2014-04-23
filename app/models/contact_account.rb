module ContactAccount
  extend ActiveSupport::Concern
  include NormalizedI18nLabels

  included do
    class_attribute :value_attr

    has_paper_trail meta: { main: :contactable }

    belongs_to :contactable, polymorphic: true

    validates :label, presence: true

    scope :public, -> { where(public: true) }

    self.labels_translations_key = 'activerecord.attributes.contact_account.predefined_labels'
  end

  def to_s(format = :default)
    "#{value} (#{label})"
  end

  def value
    send(value_attr)
  end
end