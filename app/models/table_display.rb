class TableDisplay < ActiveRecord::Base
  validates_by_schema

  belongs_to :person

  serialize :selected, Array

  class_attribute :permissions
  self.permissions = {}

  def self.for(person, parent)
    case parent
    when Group then TableDisplay::People
    when Event then TableDisplay::Participations
    end.find_or_initialize_by(person: person)
  end

  def with_permission_check(attr, object)
    permission = permissions[attr.to_s]
    yield if permission.blank? || ability.can?(permission.to_sym, object)
  end

  def ability
    @ability ||= Ability.new(person)
  end

end
