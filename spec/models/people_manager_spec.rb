# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

require "spec_helper"

describe PeopleManager do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe "validations" do
    it "requires manager and managed to be present" do
      expect(top_leader.people_manageds.build).to have(1).error_on(:managed_id)
      expect(top_leader.people_managers.build).to have(1).error_on(:manager_id)
    end

    it "does not allow manager and managed to be the same" do
      pm = PeopleManager.new(manager: top_leader, managed: top_leader)

      expect(pm).to_not be_valid
    end

    it "does not allow manager to manage same person multiple times" do
      PeopleManager.create(manager: top_leader, managed: bottom_member)

      pm = PeopleManager.new(manager: top_leader, managed: bottom_member)

      expect(pm).to_not be_valid
    end

    it "allows person to have multiple managers" do
      PeopleManager.create(manager: top_leader, managed: bottom_member)

      pm = PeopleManager.new(manager: Fabricate(:person), managed: bottom_member)

      expect(pm).to be_valid
    end

    it "allows person to have multiple manageds" do
      PeopleManager.create(manager: top_leader, managed: bottom_member)

      pm = PeopleManager.new(manager: top_leader, managed: Fabricate(:person))

      expect(pm).to be_valid
    end
  end

  it "creates managed person through nested attributes" do
    manager = top_leader.people_manageds.build(
      managed_attributes: {
        first_name: "test",
        last_name: "test"
      }
    )
    expect { manager.save! }.to change(PeopleManager, :count).by(1)
      .and change(Person, :count).by(1)
  end

  describe "paper trail", versioning: true do
    it "tracks create in papertrail" do
      manager = PeopleManager.new(manager: top_leader, managed: bottom_member)
      expect { manager.save! }.to change { PaperTrail::Version.count }.by(2)

      manager_version = PaperTrail::Version.find_by(main_id: top_leader.id, item: manager, event: "create")
      managed_version = PaperTrail::Version.find_by(main_id: bottom_member.id, item: manager, event: "create")
      expect(manager_version).to be_present
      expect(managed_version).to be_present
    end

    it "tracks destroy in papertrail" do
      manager = PeopleManager.create!(manager: top_leader, managed: bottom_member)
      expect do
        manager.destroy!
      end.to change { PaperTrail::Version.count }.by(2)

      manager_version = PaperTrail::Version.find_by(main_id: top_leader.id, item: manager, event: "destroy")
      managed_version = PaperTrail::Version.find_by(main_id: bottom_member.id, item: manager, event: "destroy")
      expect(manager_version).to be_present
      expect(managed_version).to be_present
    end
  end
end
