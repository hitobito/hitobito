# frozen_string_literal: true

#  Copyright (c) 2012-2025, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe RolesHelper do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  before do
    allow(helper).to receive(:action_name).and_return("new")
    allow(helper).to receive(:can?).and_return(true)
  end

  it "returns array of [label, sti_name] pairs" do
    options = helper.roles_type_options(group, Role.new(person:, group:))
    expect(options).to include(["External", "Role::External"])
  end

  it "returns only role types the user is allowed to create" do
    allow(helper).to receive(:can?)
      .with(:create, have_attributes(class: Role::External)).and_return(false)
    options = helper.roles_type_options(group, Role.new(person:, group:))
    expect(options).to be_present
    expect(options).not_to include(["External", "Role::External"])
  end
end
