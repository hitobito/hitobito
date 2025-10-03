# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth

require "spec_helper"

shared_examples "people_managers#create" do
  controller(described_class) do
    def create
      super { |entry| entry.call_on_yielded }
    end
  end

  before { sign_in(people(:root)) }

  context "#create" do
    let(:params) do
      attr = (described_class.assoc == :people_managers) ? :manager_id : :managed_id
      {person_id: people(:top_leader).id, people_manager: {attr => people(:bottom_member).id}}
    end

    it "yields" do
      expect_any_instance_of(PeopleManager).to receive(:call_on_yielded)

      expect { post :create, params: params }.to change { PeopleManager.count }.by(1)
    end

    it "does not create entry if yielded block raises error" do
      expect_any_instance_of(PeopleManager).to receive(:call_on_yielded).and_raise(ActiveRecord::Rollback)

      expect { post :create, params: params }
        .to not_change { PeopleManager.count }
      expect(response).to render_template(:new)
    end
  end
end

shared_examples "people_managers#destroy" do
  controller(described_class) do
    def destroy
      super { |entry| entry.call_on_yielded }
    end
  end

  let(:attr) { (described_class.assoc == :people_managers) ? :managed_id : :manager_id }
  let(:attr_opposite) { (described_class.assoc != :people_managers) ? :managed_id : :manager_id }
  let(:entry) do
    PeopleManager.create!(
      attr => people(:top_leader).id,
      attr_opposite => people(:bottom_member).id
    )
  end

  before do
    allow_any_instance_of(PeopleManager).to receive(:call_on_yielded)
    sign_in(people(:root))
  end

  def params
    {
      id: entry.id,
      person_id: entry.send(attr)
    }
  end

  context "#destroy" do
    it "deletes the correct record" do
      PeopleManager.create!(attr => people(:top_leader).id, attr_opposite => Fabricate(:person).id)
      entry # trigger let to create the entry
      PeopleManager.create!(attr => people(:top_leader).id, attr_opposite => Fabricate(:person).id)

      expect { delete :destroy, params: params }
        .to change { PeopleManager.count }.by(-1)

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not remove managed from all managers" do
      second_pm = PeopleManager.create!(manager: Fabricate(:person), managed: entry.managed)

      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { second_pm.reload }.not_to raise_error
    end

    it "yields" do
      expect_any_instance_of(PeopleManager).to receive(:call_on_yielded)
      delete :destroy, params: params

      expect { entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not destroy entry if household#remove raises error" do
      expect_any_instance_of(PeopleManager).to receive(:call_on_yielded).and_raise("baaad stuff")

      expect do
        delete :destroy, params: params
      end.to raise_error("baaad stuff")

      expect { entry.reload }.not_to raise_error
    end
  end
end
