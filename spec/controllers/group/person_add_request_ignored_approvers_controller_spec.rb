#  Copyright (c) 2012-2015 Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Group::PersonAddRequestIgnoredApproversController do
  let(:group) { groups(:top_layer) }
  let(:user) { people(:top_leader) }

  before { sign_in(user) }

  describe "PUT update" do
    it "adds entry for ignored approver" do
      expect {
        put :update, params: {group_id: group.id, person_id: user.id}
      }.to change { Person::AddRequest::IgnoredApprover.count }.by(1)
    end

    it "removes entry for added approver" do
      Person::AddRequest::IgnoredApprover.create!(group: group, person: user)
      expect {
        put :update, params: {group_id: group.id, person_id: user.id, set_approver: true}
      }.to change { Person::AddRequest::IgnoredApprover.count }.by(-1)
    end

    it "does nothing if approver is already ignored" do
      Person::AddRequest::IgnoredApprover.create!(group: group, person: user)
      expect {
        put :update, params: {group_id: group.id, person_id: user.id}
      }.not_to change { Person::AddRequest::IgnoredApprover.count }
    end

    it "does nothing if approver is already set" do
      expect {
        put :update, params: {group_id: group.id, person_id: user.id, set_approver: true}
      }.not_to change { Person::AddRequest::IgnoredApprover.count }
    end
  end
end
