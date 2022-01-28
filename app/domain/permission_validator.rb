# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PermissionValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless ability.can?(permission, value)
      record.errors[attribute] << I18n.t('errors.messages.no_permission')
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
    @ability ||= Ability.new(current_person)
  end

  def current_person
    Auth.current_person
  end
end
