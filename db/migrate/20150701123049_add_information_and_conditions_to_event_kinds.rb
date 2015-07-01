class AddInformationAndConditionsToEventKinds < ActiveRecord::Migration
  def change
    add_column(:event_kinds, :general_information, :text)
    add_column(:event_kinds, :application_conditions, :text)
  end
end
