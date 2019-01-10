class TableDisplay < ActiveRecord::Base
  validates_by_schema

  belongs_to :person

  serialize :selected, Array

  def self.for(person, parent)
    case parent
    when Group then TableDisplay::People
    when Event then TableDisplay::Participations
    end.find_or_initialize_by(person: person)
  end

  def defaults
    %w()
  end

end
