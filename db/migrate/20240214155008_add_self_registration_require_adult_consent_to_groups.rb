class AddSelfRegistrationRequireAdultConsentToGroups < ActiveRecord::Migration[6.1]
  def change
    change_table(:groups) do |t|
      t.boolean :self_registration_require_adult_consent, default: false, null: false
    end
  end
end
