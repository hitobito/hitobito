# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: label_formats
#
#  id               :integer          not null, primary key
#  name             :string(255)      not null
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

  attr_accessible :name, :page_size, :landscape, :font_size, :width, :height,
                  :padding_top, :padding_left, :count_horizontal, :count_vertical

  class << self
    def available_page_sizes
      Prawn::Document::PageGeometry::SIZES.keys
    end
  end


  validates :page_size, inclusion: available_page_sizes

  validates :width, :height, :font_size, :count_horizontal, :count_vertical,
            numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  validates :padding_top, :padding_left,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  after_save :sweep_cache
  after_destroy :sweep_cache

  class << self
    def all_as_hash
      Rails.cache.fetch('label_formats') do
        LabelFormat.order(:name).each_with_object({}) { |f, result| result[f.id] = f.to_s }
      end
    end
  end

  def to_s
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
    Rails.cache.delete('label_formats')
  end
end
