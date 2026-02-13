# frozen_string_literal: true

#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe AbilityDsl::Recorder do
  let(:store) { instance_double(AbilityDsl::Store) }
  let(:ability_class) do
    Class.new(AbilityDsl::Base) do
      def self.constraint_methods
        [:herself, :in_same_group, :everybody]
      end
    end
  end
  let(:subject_class) { Person }

  before do
    allow(store).to receive(:add)
    allow(store).to receive(:add_attribute_config)
  end

  describe AbilityDsl::Recorder::Permission do
    subject(:permission) { described_class.new(store, ability_class, subject_class, :any) }

    describe "without attribute restrictions" do
      it "only calls store.add when no attr_config is set" do
        expect(store).to receive(:add).once
        expect(store).not_to receive(:add_attribute_config)

        permission.may(:update).tap do |p|
          p.send(:constraint, :herself)
        end
      end
    end

    describe "#permitted_attrs" do
      it "does NOT call store.add for regular config" do
        expect(store).not_to receive(:add)

        permission.may(:update).permitted_attrs(:first_name).herself
      end

      it "calls store.add_attribute_config with correct parameters" do
        expected_config = have_attributes(
          permission: :any,
          subject_class: Person,
          action: :update,
          ability_class: ability_class,
          constraint: :herself,
          attrs: [:first_name],
          kind: :permit
        )

        expect(store).to receive(:add_attribute_config).with(expected_config)

        permission.may(:update).permitted_attrs(:first_name).herself
      end

      it "creates attribute config for each action" do
        expect(store).to receive(:add_attribute_config).twice

        permission.may(:update, :show).permitted_attrs(:first_name).herself
      end

      it "works with multiple attributes" do
        expected_config = have_attributes(
          attrs: [:first_name, :last_name, :email],
          kind: :permit
        )

        expect(store).to receive(:add_attribute_config).with(expected_config)

        permission.may(:update).permitted_attrs(:first_name, :last_name, :email).herself
      end
    end

    describe "#except_attrs" do
      it "calls store.add" do
        expected_config = have_attributes(
          permission: :any,
          subject_class: Person,
          action: :update,
          ability_class: ability_class,
          constraint: :herself
        )

        expect(store).to receive(:add).with(expected_config)

        permission.may(:update).except_attrs(:first_name).herself
      end

      it "calls store.add_attribute_config with correct parameters" do
        expected_config = have_attributes(
          permission: :any,
          subject_class: Person,
          action: :update,
          ability_class: ability_class,
          constraint: :herself,
          attrs: [:first_name],
          kind: :except
        )

        expect(store).to receive(:add_attribute_config).with(expected_config)

        permission.may(:update).except_attrs(:first_name).herself
      end

      it "creates both configs for each action" do
        # One add call and one add_attribute_config call per action
        expect(store).to receive(:add).twice
        expect(store).to receive(:add_attribute_config).twice

        permission.may(:update, :show).except_attrs(:first_name).herself
      end

      it "works with multiple attributes" do
        expected_config = have_attributes(
          attrs: [:first_name, :last_name, :email],
          kind: :except
        )

        expect(store).to receive(:add_attribute_config).with(expected_config)

        permission.may(:update).except_attrs(:first_name, :last_name, :email).herself
      end
    end
  end
end
