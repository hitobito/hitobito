# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Shared validation concern that ensures specified date attributes have a year
# within the accepted range: 1900..9999.
#
# Usage in a model:
#   include DateYearValidatable
#   validates_date_year :start_on, :end_on
module DateYearValidatable
  extend ActiveSupport::Concern

  included do
    class_attribute :_date_year_validated_attrs, default: []
    validate :validate_date_year_four_digits
  end

  class_methods do
    def validates_date_year(*attrs)
      self._date_year_validated_attrs = attrs
    end
  end

  private

  def validate_date_year_four_digits
    self.class._date_year_validated_attrs.each do |attribute|
      date = public_send(attribute)
      next if date.blank?

      if date.year < 1900
        errors.add(attribute, :year_must_be_after_1900)
      elsif date.year > 9999
        errors.add(attribute, :year_must_be_four_digits)
      end
    end
  end
end
