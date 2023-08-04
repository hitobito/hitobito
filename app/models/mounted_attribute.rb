
class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  validates_by_schema

  def casted_value(type)
    case type
    when :string
      value
    when :integer
      value.to_i
    when :encrypted
    when :picture
    end
  end
end
