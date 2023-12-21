# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id                :integer          not null, primary key
#  archived_at       :datetime
#  beitragskategorie :string(255)
#  convert_on        :date
#  convert_to        :string(255)
#  delete_on         :date
#  deleted_at        :datetime
#  label             :string(255)
#  type              :string(255)      not null
#  created_at        :datetime
#  updated_at        :datetime
#  group_id          :integer          not null
#  person_id         :integer          not null
#
# Indexes
#
#  index_roles_on_person_id_and_group_id  (person_id,group_id)
#  index_roles_on_type                    (type)
#
#
# Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
# hitobito_sac_cas and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito

require 'spec_helper'

describe FutureRole do
  let(:person) { people(:bottom_member) }
  let(:top_group) { groups(:top_group) }
  let(:role_type) { Group::TopGroup::Member.sti_name }
  let(:tomorrow) { Time.zone.tomorrow }

  def build(attrs = {})
    defaults = { person: person, group: top_group, convert_to: role_type, convert_on: tomorrow }
    Fabricate.build(:future_role, defaults.merge(attrs))
  end

  describe 'validations' do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.yesterday }
    let(:tomorrow) { Time.zone.tomorrow }
    subject(:error_messages) { role.errors.full_messages }

    it 'fabrication builds valid model' do
      expect(build).to be_valid
    end

    it 'is invalid with blank person or group' do
      expect(build(person: nil)).to have(1).error_on(:person)
      expect(build(group: nil)).to have(1).error_on(:group)
    end

    it 'validates that convert_on is present and not in the past' do
      expect(build(convert_on: nil)).to have(1).error_on(:convert_on)
      expect(build(convert_on: Time.zone.yesterday)).to have(1).error_on(:convert_on)
      expect(build(convert_on: Time.zone.today)).to be_valid
    end

    it 'validates that convert_to is present and of type supported by group' do
      expect(build(convert_to: nil)).to have(1).error_on(:convert_to)
      expect(build(convert_to: Group::TopLayer::TopAdmin.sti_name)).to have(1).error_on(:convert_to)
      expect(build(convert_to: Group::TopGroup::Leader.sti_name)).to be_valid
    end

    it 'validates that delete_on is not after convert_on' do
      role = build(convert_on: tomorrow + 1, delete_on: tomorrow)
      expect(role).to have(1).error_on(:delete_on)
      expect(role.errors[:delete_on].first).to eq 'kann nicht vor Von sein'
    end

    context 'target_type validations' do
      before do
        stub_const('TargetRole', Class.new(Role) do
          attr_accessor :target_type_valid

          validates :target_type_valid, presence: true
        end)
        top_group.class.role_types += [TargetRole]
      end

      after do
        top_group.class.role_types -= [TargetRole]
      end

      let(:role) { build(convert_to: TargetRole.sti_name) }

      it 'are checked if validate_target_type? returns true' do
        allow(role).to receive(:validate_target_type?).and_return(true)
        role.validate

        expect(role.errors[:target_type_valid]).to include('muss ausgefüllt werden')
      end

      it 'are skipped if validate_target_type? returns false' do
        allow(role).to receive(:validate_target_type?).and_return(false)
        role.validate

        expect(role.errors[:target_type_valid]).to be_blank
      end
    end

  end

  describe 'callbacks' do
    it 'skips create callbacks' do
      role = build
      expect(role).not_to receive(:set_contact_data_visible)
      expect(role).not_to receive(:set_first_primary_group)
      role.save!
    end

    it 'skips destroy callbacks' do
      role = build.tap(&:save!)
      expect(role).not_to receive(:reset_contact_data_visible)
      expect(role).not_to receive(:reset_primary_group)
      role.destroy!
    end

    it 'customizes item_type of papertrail versions', versioning: true do
      role = build.tap(&:save!)
      expect(PaperTrail::Version.find_by(item_type: 'FutureRole', event: :create)).to be_present
      role.destroy!
      expect(PaperTrail::Version.find_by(item_type: 'FutureRole', event: :destroy)).to be_present
    end
  end

  describe '#destroy' do
    it 'does not soft delete roles' do
      role = build.tap(&:save!)
      expect { travel_to(1.year.from_now) { role.destroy } }
        .to change { Role.count }.by(-1)
        .and(not_change { Role.deleted.count })
    end
  end

  describe '#to_s' do
    it 'includes starting date' do
      travel_to(Time.zone.local(2023, 11, 3, 14)) do
        expect(build.to_s).to eq 'Member (ab 04.11.2023)'
      end
    end
  end

  describe '#convert!' do
    it 'really_destroys self and creates new role with same attributes' do
      attrs = { created_at: 10.days.ago.noon, delete_on: 10.days.from_now.noon, label: 'test' }
      role = build(attrs).tap(&:save!)
      expect { role.convert! }.not_to(change { Role.unscoped.count })
      expect(person.roles.where(attrs.except(:created_at).merge(type: role_type))).to be_exist
    end

    it 'raises if role has invalid type' do
      role = build.tap(&:save!)
      FutureRole.where(id: role.id).update(convert_to: 'Group::TopLayer::TopAdmin')
      expect { role.convert! }.not_to raise_error
    end
  end
end
