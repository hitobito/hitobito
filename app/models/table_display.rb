#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: table_displays
#
#  id        :integer          not null, primary key
#  type      :string(255)      not null
#  person_id :integer          not null
#  selected  :text(65535)
#

class TableDisplay < ActiveRecord::Base
  validates_by_schema

  belongs_to :person

  serialize :selected, Array
  before_save :reject_internal_attributes


  def self.register_permission(model_class, permission, *attrs)
    @@permissions ||= {}
    @@permissions[model_class.model_name.singular] ||= {}
    attrs.each { |attr| @@permissions[model_class.model_name.singular][attr.to_s] = permission }
  end

  def self.for(person, parent)
    case parent
    when Group then TableDisplay::People
    when Event then TableDisplay::Participations
    end.find_or_initialize_by(person: person)
  end

  def with_permission_check(object, path)
    return yield unless selected?(path)

    target, name = resolve(object, path)
    permission = lookup_permission(target, name)
    yield target, name if permission.blank? || ability.can?(permission.to_sym, target)
  end

  def selected?(path)
    selected.collect(&:to_s).include?(path.to_s)
  end

  def resolve(object, path)
    *parts, attr = *path.to_s.split('.')
    parts.empty? ? [object, attr] : [parts.inject(object) { |obj, name| obj.send(name) }, attr]
  end

  def ability
    @ability ||= Ability.new(person)
  end

  def lookup_permission(object, name)
    @@permissions ||= {}
    @@permissions.fetch(object.class.model_name.singular, {})[name.to_s]
  end


  private

  def reject_internal_attributes
    selected.reject! do |attr|
      Person::INTERNAL_ATTRS.include?(attr.split('.').last.to_sym)
    end
  end
end
