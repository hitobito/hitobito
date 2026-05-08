class AddRolesDateIndizes < ActiveRecord::Migration[8.0]
  def change
    # depending on the query, one or the other index will be used.
    # because the role default scope contains start and end on,
    # those indizes improve the performance of many queries.
    add_index :roles, [:person_id, :start_on, :end_on]
    add_index :roles, [:group_id, :person_id, :start_on, :end_on]
  end
end
