class TableDisplay < ActiveRecord::Base
  validates_by_schema

  serialize :selected, Array
end
