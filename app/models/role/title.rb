# frozen_string_literal: true
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

class Role::Title
  delegate :group, :convert_to, :convert_on, :convert_on?, :delete_on, :delete_on?, :label, :label?,
    to: '@role'

  KEYS = [:label, :convert_on, :delete_on]

  def initialize(role, format: :default)
    @role = role
    @format = format
  end

  def to_s
    text = build(:label, :convert_on)
    return text unless long?

    I18n.t('activerecord.attributes.role.string_long', role: text, group: group.to_s)
  end

  def parts(*keys)
    (keys.presence || KEYS).collect { |key| part(key) }.compact
  end

  def model_name
    case @role
    when FutureRole then convert_to.constantize.model_name.human
    else @role.class.label
    end
  end

  private

  def part(key)
    case key
    when :label then wrap(label) if label?
    when :delete_on then wrap(formatted_delete_date) if delete_on?
    when :convert_on then wrap(formatted_convert_date) if convert_on?
    end
  end

  def build(*keys)
    parts(*keys).prepend(model_name).join(" ")
  end

  def long?
    @format == :long
  end

  def wrap(text)
    "(#{text})"
  end

  def formatted_convert_date
    I18n.t('global.start_on', date: I18n.l(convert_on))
  end

  def formatted_delete_date
    [I18n.t('global.until').downcase, I18n.l(delete_on)].join(' ')
  end
end
