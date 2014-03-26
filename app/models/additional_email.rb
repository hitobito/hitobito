# == Schema Information
#
# Table name: additional_emails
#
#  id               :integer          not null, primary key
#  contactable_id   :integer          not null
#  contactable_type :string(255)      not null
#  email            :string(255)      not null
#  label            :string(255)
#  public           :boolean          default(TRUE), not null
#  mailings         :boolean          default(TRUE), not null
#

class AdditionalEmail < ActiveRecord::Base

  include NormalizedLabels

  has_paper_trail meta: { main: :contactable }

  belongs_to :contactable, polymorphic: true

  validates :label, presence: true
  validates :email, format: Devise.email_regexp

  class << self
    def load_available_labels
      Settings.additional_email.predefined_labels | super
    end
  end

  def to_s(format = :default)
    "#{email} (#{label})"
  end

end
