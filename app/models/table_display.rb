#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: table_displays
#
#  id        :integer          not null, primary key
#  selected  :text(16777215)
#  type      :string(255)      not null
#  person_id :integer          not null
#
# Indexes
#
#  index_table_displays_on_person_id_and_type  (person_id,type) UNIQUE
#

class TableDisplay < ActiveRecord::Base
  validates_by_schema

  belongs_to :person

  serialize :selected, Array
  before_save :allow_only_known_attributes!

  def self.register_permission(model_class, permission, *attrs)
    @@permissions ||= {}
    @@permissions[model_class.model_name.singular] ||= {}
    attrs.each { |attr| @@permissions[model_class.model_name.singular][attr.to_s] = permission }
  end

  def self.for(person, parent)
    case parent
    when Group then TableDisplay::People
    when Event then TableDisplay::Participations
    end.find_or_initialize_by(person: person).allow_only_known_attributes!
  end

  def table_model_class
    raise 'implement in subclass'
  end

  def with_permission_check(object, path)
    return yield unless selected?(path)

    target, name = resolve(object, path)
    permission = lookup_permission(target, name)
    yield target, name if ability.can?(permission.to_sym, target)
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

  def available
    @@permissions.fetch(table_model_class.model_name.singular, {}).keys
  end

  protected

  def allow_only_known_attributes!
    selected.select! { |attr| known?(attr) }
    self
  end

  def known?(attr)
    available.include?(attr.to_s)
  end
end
