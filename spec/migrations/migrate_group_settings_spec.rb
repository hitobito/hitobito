# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#

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
        s = MigrateGroupSettings::LegacyGroupSetting.new({
          var: :messages_letter,
          target: group
        })

        s.picture.attach(
          io: File.open('spec/fixtures/files/images/logo.png'),
          filename: 'logo.png'
        )

        s.save!
        ActiveStorage::Attachment.update_all(record_type: 'RailsSettings::SettingObject')
        s
      end
    end

    let(:encrypted_group_settings) do
      layers.map do |group|
        encrypted = EncryptionService.encrypt('bla')
        MigrateGroupSettings::LegacyGroupSetting.create!({
          var: :text_message_provider,
          target: group,
          value: {
            'encrypted_username' => encrypted
          }
        })
      end
    end

    let(:group_settings) do
      layers.map do |group|
        MigrateGroupSettings::LegacyGroupSetting.create!({
          var: :text_message_provider,
          target: group,
          value: {
            'originator' => 'bla'
          }
        })
      end
    end

    before do
      migration.down
      groups.each { |g| g.letter_logo.purge }

      MigrateGroupSettings::LegacyGroupSetting.destroy_all
    end

    it 'migrates picture settings' do
      layers = picture_group_settings.map(&:target)
      layers.each do |group|
        expect(group.letter_logo).to_not be_attached
      end
      expect do
        migration.up
      end.to change { ActiveStorage::Attachment.where(record_type: 'RailsSettings::SettingObject').count }.by(-2)

      expect(ActiveRecord::Base.connection.table_exists?('settings')).to eq(false)

      layers.each do |group|
        group.reload
        expect(group.letter_logo).to be_attached
      end
    end

    it 'migrates encrypted settings' do
      encrypted_group_settings.each do |s|
        encrypted = s.value['encrypted_username']
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end

      migration.up

      layers.each do |group|
        group.reload
        expect(group.text_message_username).to be_present
        expect(group.text_message_username).to eq('bla')
      end

      expect(ActiveRecord::Base.connection.table_exists?('settings')).to eq(false)
    end

    it 'migrates regular settings' do
      group_settings.each do |s|
        value = s.value['originator']

        expect(value).to be_present
        expect(value).to eq('bla')
      end

      migration.up

      layers.each do |group|
        group.reload
        expect(group.text_message_originator).to be_present
        expect(group.text_message_originator).to eq('bla')
      end
    end

    it 'does not remove group setting with wagon specific keys' do
      group_settings.each do |s|
        s.value['wagon_sender'] = 'David Hasselhoff'
        s.save!
      end

      expect do
        migration.up
      end.to change { MigrateGroupSettings::LegacyGroupSetting.count }.by(0)

      expect(ActiveRecord::Base.connection.table_exists?('settings')).to eq(true)
    end
  end

  context '#down' do
    let!(:picture_groups) do
      layers.map do |group|
        group.letter_logo.attach(
          io: File.open('spec/fixtures/files/images/logo.png'),
          filename: 'logo.png'
        )

        group.save!

        group
      end
    end

    let!(:encrypted_layers) do
      layers.map do |group|
        group.text_message_username = 'bla'
        group.save!
        group
      end
    end

    let!(:regular_layers) do
      layers.map do |group|
        group.text_message_originator = 'bla'
        group.save!
        group
      end
    end

    after do
      migration.up
    end

    it 'migrates picture attr' do
      layers.each do |group|
        expect(group.letter_logo).to be_attached
      end

      migration.down

      layers.each do |group|
        group.reload
        expect(group.letter_logo).to_not be_attached

        setting = MigrateGroupSettings::LegacyGroupSetting.find_by(target: group,
                                                                      var: :messages_letter)
        expect(ActiveStorage::Attachment.exists?(record_type: 'RailsSettings::SettingObject', record_id: setting.id)).to eq(true)
      end
    end

    it 'migrates encrypted settings' do
      encrypted_layers.each do |a|
        encrypted = a.encrypted_text_message_username
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end

      migration.down

      layers.each do |group|
        setting = MigrateGroupSettings::LegacyGroupSetting.find_by(target: group,
                                                                      var: :text_message_provider)
        encrypted = setting.value['encrypted_username']
        expect(encrypted).to be_present
        expect(EncryptionService.decrypt(encrypted[:encrypted_value], encrypted[:iv])).to eq('bla')
      end
    end

    it 'migrates regular settings' do
      regular_layers.each do |a|
        expect(a.text_message_originator).to be_present
        expect(a.text_message_originator).to eq('bla')
      end

      migration.down

      layers.each do |group|
        setting = MigrateGroupSettings::LegacyGroupSetting.find_by(target: group,
                                                                      var: :text_message_provider)
        expect(setting.value['originator']).to be_present
        expect(setting.value['originator']).to eq('bla')
      end
    end
  end
end
