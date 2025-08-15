# frozen_string_literal: true

#  Copyright (c) 2012-2024, Die Mitte Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module PostalAddress
  def address
    parts = [street, housenumber].compact
    return nil if parts.blank?

    parts.join(" ")
  end

  def country_label
    Countries.label(country)
  end

  def country=(value)
    super(Countries.normalize(value))
  end

  def ignored_country?
    swiss?
  end

  def swiss?
    Countries.swiss?(country)
  end

  def canton
    (swiss? && location&.canton) || nil
  end

  private

  # rubocop:todo Layout/LineLength
  # to validate zip codes to swiss zip code format when country is nil, we return :ch format as the default
  # rubocop:enable Layout/LineLength
  # option when country is nil
  def zip_country
    self[:country] || :ch
  end
end
