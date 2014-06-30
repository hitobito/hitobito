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
#  font_size        :float            default(11.0), not null
#  width            :float            not null
#  height           :float            not null
#  count_horizontal :integer          not null
#  count_vertical   :integer          not null
#  padding_top      :float            not null
#  padding_left     :float            not null
#
class LabelFormat < ActiveRecord::Base

  class << self
    def available_page_sizes
      PDF::Core::PageGeometry::SIZES.keys
    end
  end

  include Globalized
  translates :name


  validates :name, presence: true, length: { maximum: 255, allow_nil: true }
  validates :page_size, inclusion: available_page_sizes

  validates :width, :height, :font_size, :count_horizontal, :count_vertical,
            numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  validates :padding_top, :padding_left,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  validates :padding_top, numericality: { less_than: :height }
  validates :padding_left, numericality: { less_than: :width }

  after_save :sweep_cache
  after_destroy :sweep_cache

  class << self
    def all_as_hash
      Rails.cache.fetch("label_formats_#{I18n.locale}") do
        LabelFormat.list.each_with_object({}) { |f, result| result[f.id] = f.to_s }
      end
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

  private

  def sweep_cache
    Settings.application.languages.to_hash.keys.each do |lang|
      Rails.cache.delete("label_formats_#{lang}")
    end
  end

end
