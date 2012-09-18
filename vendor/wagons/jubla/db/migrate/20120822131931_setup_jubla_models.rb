class SetupJublaModels < ActiveRecord::Migration
  def change
    add_column :people, :name_mother, :string
    add_column :people, :name_father, :string
    
    add_column :people, :nationality, :string
    add_column :people, :profession, :string
    add_column :people, :bank_account, :string
    
    add_column :people, :ahv_number, :string
    add_column :people, :ahv_number_old, :string
    add_column :people, :j_s_number, :string
    add_column :people, :insurance_company, :string
    add_column :people, :insurance_number, :string
    
    
    add_column :groups, :bank_account, :string
    add_column :groups, :jubla_insurance, :boolean, null: false, default: false
    add_column :groups, :jubla_full_coverage, :boolean, null: false, default: false
    
    add_column :groups, :parish, :string
    add_column :groups, :kind, :string
    add_column :groups, :unsexed, :boolean, null: false, default: false
    add_column :groups, :clairongarde, :boolean, null: false, default: false
    add_column :groups, :founding_year, :integer
    
    add_column :groups, :coach_id, :integer
    add_column :groups, :advisor_id, :integer
    
    
    add_column :roles, :employment_percent, :integer
    add_column :roles, :honorary, :boolean
  end
end
