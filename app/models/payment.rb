class Payment < ActiveRecord::Base
  belongs_to :invoice

  after_create :update_invoice

  scope :list, -> { order(created_at: :desc) }

  validates_by_schema

  def group
    invoice.group
  end

  private

  def update_invoice
    if amount >= invoice.total
      invoice.update(state: :payed)
    end
  end

end
