# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CondensedContact
  CONDENSABLE_ATTRIBUTES = [:address, :last_name, :zip_code, :town, :country]

  attr_accessor :base_contactable, :merged_contactables
  delegate(*CONDENSABLE_ATTRIBUTES, to: :@base_contactable)

  def initialize(base_contactable, *contactables)
    self.base_contactable = base_contactable
    self.merged_contactables = contactables
  end

  def contactables
    [base_contactable] + merged_contactables
  end

  def full_name
    "#{contactables.map(&:first_name).to_sentence} #{base_contactable.last_name}"
  end

  def condensable?(contactable)
    CondensedContact.condensable?(self, contactable)
  end

  def condense(contactable)
    merged_contactables << contactable if condensable?(contactable)
  end
  alias_method :<<, :condense

  def self.condensable?(base_contactable, contactable)
    CONDENSABLE_ATTRIBUTES.each do |attribute|
      return false unless base_contactable.try(attribute) == contactable.try(attribute)
    end
    true
  end

end
