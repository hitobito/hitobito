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
#  finish_at             :date
#  origin                :string(255)
#  start_at              :date             not null
#  person_id             :integer          not null
#  qualification_kind_id :integer          not null
#
# Indexes
#
#  index_qualifications_on_person_id              (person_id)
#  index_qualifications_on_qualification_kind_id  (qualification_kind_id)
#

class Qualification < ActiveRecord::Base

  attr_writer :first_of_kind
  attr_accessor :open_training_days

  ### ASSOCIATIONS

  belongs_to :person
  belongs_to :qualification_kind

  has_paper_trail meta: { main_id: ->(q) { q.person_id }, main_type: Person.sti_name }

  ### VALIDATIONS

  before_validation :set_finish_at

  validates_by_schema
  validates :qualification_kind_id,
            uniqueness: { scope: [:person_id, :start_at, :finish_at],
                          message: :exists_for_timeframe }
  validates :start_at, :finish_at,
            timeliness: { type: :date, allow_blank: true, before: Date.new(9999, 12, 31) }


  delegate :cover?, :active?, to: :duration

  class << self

    def order_by_date
      order(Arel.sql('CASE WHEN finish_at IS NULL THEN 0 ELSE 1 END, finish_at DESC'))
    end

    def active(date = nil)
      date ||= Time.zone.today
      where('qualifications.start_at <= ?', date).
        where('qualifications.finish_at >= ? OR qualifications.finish_at IS NULL', date)
    end

    def reactivateable(date = nil)
      date ||= Time.zone.today
      joins(:qualification_kind).
        where('qualifications.start_at <= ?', date).
        where('qualifications.finish_at IS NULL OR ' \
              '(qualification_kinds.reactivateable IS NULL AND ' \
              ' qualifications.finish_at >= :date) OR ' \
              'DATE_ADD(qualifications.finish_at, ' \
              ' INTERVAL qualification_kinds.reactivateable YEAR) >= :date',
              date: date)
    end

    def only_reactivateable(date = nil)
      date ||= Time.zone.today
      joins(:qualification_kind).
        where.not(finish_at: nil).
        where.not(qualification_kinds: { reactivateable: nil }).
        where('qualifications.finish_at < :date AND ' \
              'DATE_ADD(qualifications.finish_at, ' \
              ' INTERVAL qualification_kinds.reactivateable YEAR) >= :date',
              date: date)
    end

    def not_active(qualification_kind_ids = [], date = nil) # rubocop:disable Metrics/MethodLength
      date ||= Time.zone.today
      kind_condition =
        if qualification_kind_ids.present?
          'q2.qualification_kind_id IN (:qualification_kind_ids)'
        else
          'q2.qualification_kind_id = qualifications.qualification_kind_id'
        end
      where('NOT EXISTS (SELECT 1 FROM qualifications q2 ' \
            'WHERE q2.person_id = qualifications.person_id ' \
            "AND #{kind_condition} " \
            'AND q2.start_at <= :date  ' \
            'AND (q2.finish_at IS NULL OR q2.finish_at >= :date))',
            qualification_kind_ids: qualification_kind_ids, date: date)
    end

  end

  def duration
    @duration ||= Duration.new(start_at, finish_at)
  end

  def reactivateable_until
    return unless finish_at

    finish_at + qualification_kind.reactivateable.to_i.years
  end

  def reactivateable?(date = nil)
    date ||= Time.zone.today
    finish_at.nil? || (reactivateable_until && reactivateable_until >= date)
  end

  def to_s(format = :default)
    I18n.t("activerecord.attributes.qualification.#{to_s_key(format)}",
           kind: qualification_kind.to_s,
           finish_at: finish_at? ? I18n.l(finish_at) : nil,
           origin: origin)
  end

  def first_reactivateable?
    @first_of_kind && reactivateable?
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
