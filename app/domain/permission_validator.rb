# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PermissionValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # We cannot validate permission if no person is logged in.
    # Other mechanisms such as authorize_resource should be used to prevent this case.
    return unless current_person

    unless ability.can?(permission, value)
      record.errors.add(attribute, I18n.t('errors.messages.no_permission'))
    end
  end

  private

  def permission
    case options[:with]
    when Symbol
      options[:with]
    when String
      options[:with].to_sym
    else
      :show
    end
  end

  def ability
    # This must not be cached, because the same validator is re-used between tests.
    # If we cached this, the tests would become inter-dependent:
    # ability.user would potentially be an old value from another test
    Ability.new(current_person)
  end

  def current_person
    Auth.current_person
  end
end
