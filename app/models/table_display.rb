class TableDisplay < ActiveRecord::Base
  validates_by_schema

  serialize :columns, Hash
end
