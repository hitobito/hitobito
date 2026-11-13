# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe Roles::TypeChange do
  let(:old_role) { roles(:bottom_member) }
  let(:new_role) do
    Group::BottomLayer::Leader.new(person: old_role.person, group: old_role.group)
  end

  subject(:type_change) { described_class.new(old_role, new_role) }

  it "replaces the old role by the new role" do
    expect(type_change.call).to be true

    expect(new_role).to be_persisted
    expect(Role.exists?(old_role.id)).to be false
  end

  it "keeps the old role when the new role is invalid" do
    new_role.person = nil

    expect(type_change.call).to be_falsy

    expect(new_role).not_to be_persisted
    expect(Role.with_inactive.find(old_role.id).end_on).to be_nil
  end

  it "does not save the new role when the old role cannot be destroyed" do
    allow(old_role).to receive(:destroy).and_return(false)

    expect(type_change.call).to be_falsy

    expect(new_role).not_to be_persisted
  end
end
