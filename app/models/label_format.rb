# encoding: utf-8

#
#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: label_formats
#
#  id               :integer          not null, primary key
#  page_size        :string(255)      default("A4"), not null
#  landscape        :boolean          default(FALSE), not null
#  font_size        :float(24)        default(11.0), not null
#  width            :float(24)        not null
#  height           :float(24)        not null
#  count_horizontal :integer          not null
#  count_vertical   :integer          not null
#  padding_top      :float(24)        not null
#  padding_left     :float(24)        not null
#  person_id        :integer
#  nickname         :boolean          default(FALSE), not null
#  pp_post          :string(23)
#

class LabelFormat < ActiveRecord::Base
  class << self
    def available_page_sizes
      PDF::Core::PageGeometry::SIZES.keys
    end
  end

  include Globalized
  translates :name

  has_many :people, foreign_key: :last_label_format_id, dependent: :nullify

  belongs_to :person

  validates :name, presence: true, length: {maximum: 255, allow_nil: true}
  validates :page_size, inclusion: available_page_sizes

  validates_by_schema
  validates :width, :height, :font_size, :count_horizontal, :count_vertical,
    numericality: {greater_than_or_equal_to: 1, allow_nil: true}

  validates :padding_top, :padding_left,
    numericality: {greater_than_or_equal_to: 0, allow_nil: true}

  validates :padding_top, numericality: {less_than: :height, if: :height}
  validates :padding_left, numericality: {less_than: :width, if: :width}

  scope :for_user, ->(user) { where("user_id = ? OR user_id IS null", user.id) }

  def self.for_person(person)
    if person.show_global_label_formats?
      where("person_id = ? OR person_id IS NULL", person.id)
    else
      where(person_id: person.id)
    end
  end

  def to_s(_format = :default)
    "#{name} (#{page_size}, #{dimensions})"
  end

  def dimensions
    "#{count_horizontal}x#{count_vertical}"
  end

  def page_layout
    landscape ? :landscape : :portrait
  end
end
