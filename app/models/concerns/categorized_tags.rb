module CategorizedTags
  extend ActiveSupport::Concern

  included do
    before_validation :strip_name
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

  module ClassMethods
    def grouped_by_category
      tags = order(:name).each_with_object({}) do |tag, h|
        category = tag.category
        h[category] ||= []
        h[category] << tag
      end
      order_categorized(tags)
    end

    def order_categorized(tags)
      tags.to_a.sort do |a, b|
        if a[0] == :category_validation && b[0] == :other
          -1
        elsif %i[other category_validation].include?(a[0]) || a[0] > b[0]
          1
        elsif a[0] < b[0]
          -1
        else
          0
        end
      end
    end

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
end
