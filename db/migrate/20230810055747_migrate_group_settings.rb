class MigrateGroupSettings < ActiveRecord::Migration[6.1]

  VAR_MAPPING = {
    text_message_username: :text_message_provider,
    text_message_password: :text_message_provider,
    text_message_provider: :text_message_provider,
    text_message_originator: :text_message_provider,
    address_position: :messages_letter,
    letter_logo: :messages_letter
  }

  KEY_MAPPING = {
    encrypted_username: :text_message_username,
    encrypted_password: :text_message_password,
    provider: :text_message_provider,
    originator: :text_message_originator,
    address_position: :address_position,
    picture: :letter_logo
  }

  class MigrationGroupSetting < ActiveRecord::Base
    self.table_name = 'settings'

    serialize :value, Hash
  end

  class MigrationMountedAttribute < ActiveRecord::Base
    self.table_name = 'mounted_attributes'

    serialize :value
  end

  def up
    say_with_time('migrate group settings to mounted attributes') do
      migrate_settings
      drop_table(:settings)
    end
  end

  def down
    create_table :settings do |t|
      t.string     :var, null: false
      t.text       :value
      t.references :target, null: false, polymorphic: true
      t.timestamps null: true
    end
    add_index :settings, [:target_type, :target_id, :var], unique: true

    say_with_time('revert mounted attributes to group settings') do
      revert_mounted_attributes
    end
  end

  private

  def migrate_settings
    MigrationGroupSetting.find_each do |setting|
      setting.value.each do |key, value|
        MigrationMountedAttribute.create!(entry_type: Group.find(setting.target_id).type,
                                          entry_id: setting.target_id,
                                          key: KEY_MAPPING[key.to_sym],
                                          value: value)
      end
    end
  end

  def revert_mounted_attributes
    relevant_group_ids = MigrationMountedAttribute.where(entry_type: Group.subclasses).pluck(:entry_id)
    Group.where(id: relevant_group_ids).find_each do |group|
      values_for_var = { messages_letter: {}, text_message_provider: {} }

      MigrationMountedAttribute.where(entry_type: group.type, entry_id: group.id).find_each do |a|
        values_for_var[VAR_MAPPING[a.key.to_sym]][KEY_MAPPING.invert[a.key.to_sym].to_s] = a.value
      end

      values_for_var.each do |var, values|
        MigrationGroupSetting.create!(target_type: Group.sti_name,
                                      target_id: group.id,
                                      var: var,
                                      value: values)
      end
    end
  end
end
