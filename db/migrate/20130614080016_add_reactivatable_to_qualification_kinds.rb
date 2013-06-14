class AddReactivatableToQualificationKinds < ActiveRecord::Migration
  def change
    add_column(:qualification_kinds, :reactivateable, :integer)
  end
end
