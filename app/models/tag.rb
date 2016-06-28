# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class Tag < ActiveRecord::Base

  belongs_to :taggable, polymorphic: true

  validates :name, presence: true,
                   uniqueness: { scope: [:taggable_id, :taggable_type],
                                 message: :must_be_unique }

  scope :grouped_by_category, -> do
    order(:name).
      each_with_object({}) { |tag, h| h[tag.category] ||= []; h[tag.category] << tag }.
      to_a.
      sort do |a, b|
        if a[0] == :other || a[0] > b[0]; 1
        elsif a[0] < b[0]; -1
        else; 0
        end
    end
  end

  def to_s
    "#{name}: #{taggable}"
  end

  def category
    m = name.match /^([^:]+):(.+)$/ if name.present?
    m ? m[1].strip.to_sym : :other
  end

  def name_without_category
    m = name.match /^([^:]+):(.+)$/ if name.present?
    m ? m[2].strip : name
  end

end
