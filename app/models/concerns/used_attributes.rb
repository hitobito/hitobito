# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UsedAttributes
  extend ActiveSupport::Concern

  # This is intended for STI classes to limit attributes used on the
  # specific STI subclass (Course ->  Event, role or group subtypes)

  included do
    class_attribute :used_attributes
  end

  def attr_used?(attr)
    self.class.attr_used?(attr)
  end

  module ClassMethods
    def attr_used?(attr)
      used_attributes.map(&:to_s).include?(attr.to_s)
    end
  end
end
