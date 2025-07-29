# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe People::AddressesSyncsController do
  before { sign_in(person) }

  let(:top_layer) { groups(:top_layer) }

  context "with admin permission" do
    let(:person) { Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person }

    it "enqueues job" do
      expect do
        post :create, params: {group_id: top_layer.id}
      end.to change { Delayed::Job.count }.by(1)
      expect(flash[:notice]).to eq "Der Adressenabgleich wurde erfolgreich gestartet."
    end

    it "notifies if job is already running" do
      AddressSynchronizationJob.new.enqueue!
      expect do
        post :create, params: {group_id: top_layer.id}
      end.not_to change { Delayed::Job.count }
      expect(flash[:alert]).to eq "Aktuell ist noch ein Adressenabgleich in Arbeit."
    end
  end

  context "without admin permission" do
    let(:person) { Fabricate(Group::TopLayer::TopAdmin.sti_name, group: groups(:top_layer)).person }

    it "is not authorized" do
      expect do
        post :create, params: {group_id: top_layer.id}
      end.to raise_error(CanCan::AccessDenied)
    end
  end
end
