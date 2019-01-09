class TableDisplay < ActiveRecord::Base
  validates_by_schema
  after_initialize :assign_default_selection

  belongs_to :parent, polymorphic: true
  belongs_to :person

  serialize :selected, Array

  def self.for(person, parent)
    model_class = case parent
                  when Group then TableDisplay::People
                  when Event then TableDisplay::Participations
                  end

    model_class.find_or_initialize_by(person: person, parent: parent)
  end

  def assign_default_selection
    self.selected = defaults if selected.empty? && new_record?
  end

end
