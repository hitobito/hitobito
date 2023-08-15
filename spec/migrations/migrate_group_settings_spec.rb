require 'spec_helper'
migration_file_name = Dir[Rails.root.join('db/migrate/20230810055747_migrate_group_settings.rb')].first
require migration_file_name

describe MigrateGroupSettings do
  before(:all) { self.use_transactional_tests = false }
  after(:all)  { self.use_transactional_tests = true }

  let(:migration) { described_class.new.tap { |m| m.verbose = false } }

  let(:layers) do
    [groups(:bottom_layer_one), groups(:bottom_layer_two)]
  end

  context '#up' do
    let(:picture_group_settings) do
      layers.map do |group|
        s = MigrateGroupSettings::MigrationGroupSetting.new({
          var: :messages_letter,
          target: group,
          value: {
            picture: nil
          }
        })

        s.picture.attach(
          io: File.open('spec/fixtures/files/images/logo.png'),
          filename: 'logo.png'
        )

        s.save!

        s
      end
    end

    let(:encrypted_group_settings) do
      layers.map do |group|
        encrypted = EncryptionService.encrypt('bla')
        MigrateGroupSettings::MigrationGroupSetting.create!({
          var: :text_message_provider,
          target: group,
          value: {
            encrypted_username: encrypted
          }
        })
      end
    end

    let(:group_settings) do
      layers.map do |group|
        MigrateGroupSettings::MigrationGroupSetting.create!({
          var: :text_message_provider,
          target: group,
          value: {
            originator: 'bla'
          }
        })
      end
    end

    before do
      migration.down

      MigrateGroupSettings::MigrationGroupSetting.delete_all
      groups.each { |g| g.letter_logo.purge }
    end

    it 'migrates picture settings' do
      layers = picture_group_settings.map(&:target)
      layers.each do |group|
        expect(group.letter_logo).to_not be_attached
      end
      migration.up
      layers.each do |group|
        group.reload
        expect(group.letter_logo).to be_attached
      end
    end

    it 'migrates encrypted settings' do
      encrypted_group_settings.each do |s|
        encrypted = s.value[:encrypted_username]
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end

      migration.up

      layers.each do |group|
        expect(group.text_message_username).to be_present
        expect(group.text_message_username).to eq('bla')
      end
    end

    it 'migrates regular settings' do
      group_settings.each do |s|
        value = s.value[:originator]
        expect(value).to be_present
        expect(value).to eq('bla')
      end

      migration.up

      layers.each do |group|
        expect(group.text_message_originator).to be_present
        expect(group.text_message_originator).to eq('bla')
      end
    end
  end

  context '#down' do
    let!(:picture_groups) do
      layers.map do |group|
        MigrateGroupSettings::MigrationMountedAttribute.create!({
          entry: group,
          key: :letter_logo
        })

        group.letter_logo.attach(
          io: File.open('spec/fixtures/files/images/logo.png'),
          filename: 'logo.png'
        )

        group.save!

        group
      end
    end

    let!(:encrypted_mounted_attrs) do
      layers.map do |group|
        encrypted = EncryptionService.encrypt('bla')
        MigrateGroupSettings::MigrationMountedAttribute.create!({
          entry: group,
          key: :text_message_username,
          value: encrypted
        })
      end
    end

    let!(:regular_mounted_attrs) do
      layers.map do |group|
        MigrateGroupSettings::MigrationMountedAttribute.create!({
          entry: group,
          key: :text_message_originator,
          value: 'bla'
        })
      end
    end

    after do
      migration.up
      MigrateGroupSettings::MigrationMountedAttribute.delete_all
    end

    it 'migrates picture attr' do
      layers.each do |group|
        expect(group.letter_logo).to be_attached
      end

      migration.down

      layers.each do |group|
        group.reload
        expect(group.letter_logo).to_not be_attached

        setting = MigrateGroupSettings::MigrationGroupSetting.find_by(target: group,
                                                                      var: :text_message_provider)
        expect(setting.picture).to be_attached
      end
    end

    it 'migrates encrypted settings' do
      encrypted_mounted_attrs.each do |a|
        encrypted = a.value
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end

      migration.down

      layers.each do |group|
        setting = MigrateGroupSettings::MigrationGroupSetting.find_by(target: group,
                                                                      var: :text_message_provider)
        encrypted = setting.value['encrypted_username']
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end
    end

    it 'migrates regular settings' do
      regular_mounted_attrs.each do |a|
        expect(a.value).to be_present
        expect(a.value).to eq('bla')
      end

      migration.down

      layers.each do |group|
        setting = MigrateGroupSettings::MigrationGroupSetting.find_by(target: group,
                                                                      var: :text_message_provider)
        expect(setting.value['originator']).to be_present
        expect(setting.value['originator']).to eq('bla')
      end
    end
  end
end
