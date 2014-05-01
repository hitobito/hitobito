# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: qualifications
#
#  id                    :integer          not null, primary key
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#  start_at              :date             not null
#  finish_at             :date
#  origin                :string(255)
#

class Qualification < ActiveRecord::Base

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :qualification_kind

  has_paper_trail meta: { main_id: ->(q) { q.person_id }, main_type: Person.sti_name }

  ### VALIDATIONS

  before_validation :set_finish_at

  validates :qualification_kind_id,
            uniqueness: { scope: [:person_id, :start_at, :finish_at],
                          message: :exists_for_timeframe  }
  validates :start_at, :finish_at,
            timeliness: { type: :date, allow_blank: true }


  delegate :cover?, :active?, to: :duration

  class << self
    def active(date = nil)
      date ||= Date.today
      where('qualifications.start_at <= ?', date).
        where('qualifications.finish_at >= ? OR qualifications.finish_at IS NULL', date)
    end

    def order_by_date
      order('finish_at DESC')
    end
  end

  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def reactivateable?(date = nil)
    date ||= Date.today
    finish_at.nil? || (finish_at + qualification_kind.reactivateable.to_i.years) >= date
  end

  def to_s(format = :default)
    I18n.t("activerecord.attributes.qualification.#{to_s_key(format)}",
           kind: qualification_kind.to_s,
           finish_at: finish_at? ? I18n.l(finish_at) : nil,
           origin: origin)
  end

  private

  def set_finish_at
    if start_at? && qualification_kind && qualification_kind.validity
      self.finish_at = (start_at + qualification_kind.validity.years).end_of_year
    end
  end

  def to_s_key(format = :default)
    cols = []
    cols << :finish_at if finish_at?
    cols << :origin if format == :long && origin?

    ['string', cols.join('_and_').presence].compact.join('_with_')
  end

end
