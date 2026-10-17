# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::Contact < Person
  attr_writer :visible_contact_attributes

  def visible_contact_attributes
    @visible_contact_attributes || Event::ALLOWED_VISIBLE_CONTACT_ATTRIBUTES
  end

  def contact_attribute_visible?(attr)
    visible_contact_attributes.include?(attr.to_s)
  end
end
