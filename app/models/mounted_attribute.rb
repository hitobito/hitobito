
class MountedAttribute < ActiveRecord::Base
  belongs_to :entry, polymorphic: true

  validates_by_schema
end
