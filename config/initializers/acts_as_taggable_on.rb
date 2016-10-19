# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

ActsAsTaggableOn.remove_unused_tags = true
ActsAsTaggableOn.default_parser = TagCategoryParser


ActsAsTaggableOn::Tag.class_eval do

  before_validation :strip_name

  scope :grouped_by_category, lambda {
    tags = order(:name).each_with_object({}) do |tag, h|
      category = tag.category
      h[category] ||= []
      h[category] << tag
    end
    tags.to_a.sort do |a, b|
      if a[0] == :other || a[0] > b[0]
        1
      elsif a[0] < b[0]
        -1
      else
        0
      end
    end
  }

  class << self

    def parse_category(str)
      m = str.match(/^([^:]+):(.+)$/) if str.present?
      m ? m[1].strip.to_sym : :other
    end

    def parse_name_without_category(str)
      m = str.match(/^([^:]+):(.+)$/) if str.present?
      m ? m[2].strip : str.strip
    end

    def strip(str)
      c = parse_category(str)
      n = parse_name_without_category(str)
      c == :other ? n : "#{c}:#{n}"
    end

  end

  def category
    self.class.parse_category(name)
  end

  def name_without_category
    self.class.parse_name_without_category(name)
  end

  private

  def strip_name
    self.name = self.class.strip(name)
  end

end
