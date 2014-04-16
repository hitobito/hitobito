module ContactAccount
  extend ActiveSupport::Concern

  included do
    class_attribute :value_attr

    has_paper_trail meta: { main: :contactable }

    belongs_to :contactable, polymorphic: true

    validates :label, presence: true

    scope :public, -> { where(public: true) }
  end

  def to_s(format = :default)
    "#{value} (#{label})"
  end

  def value
    send(value_attr)
  end

end