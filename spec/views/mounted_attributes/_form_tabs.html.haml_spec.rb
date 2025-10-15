# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "mounted_attributes/_form_tabs.html.haml" do
  let(:group) do
    stub_const("TestGroup", Class.new(Group) do
      mounted_attr :test_attr, :string
      mounted_attr :test_enum, :string, enum: %i[the_only_option]
      mounted_attr :test_readonly, :string, readonly: true
      mounted_attr :enum_readonly, :string, enum: %i[the_only_option], readonly: true
    end)
    GroupDecorator.new(TestGroup.new)
  end

  let(:ability) { Object.new.extend(CanCan::Ability) }

  around do |example|
    with_translations(
      de: {activerecord: {attributes: {test_group: {
        test_enums: {the_only_option: "The only option"},
        enum_readonlys: {the_only_option: "The only option"}
      }}}}
    ) do
      example.call
    end
  end

  let(:form_builder) { StandardFormBuilder.new(:group, group, view, {}) }

  before do
    allow(view).to receive_messages(
      entry: group,
      f: form_builder
    )
    allow(view.controller).to receive(:current_ability).and_return(ability)
  end

  subject { Capybara::Node::Simple.new(raw(rendered)) }

  before { render }

  it "renders input field" do
    expect(subject).to have_selector('input#group_test_attr[type="text"]')
    expect(subject.find("input#group_test_attr")).not_to be_disabled
  end

  it "renders enum select" do
    expect(subject).to have_selector('select#group_test_enum option[value="the_only_option"]',
      text: "The only option")
    expect(subject.find("select#group_test_enum")).not_to be_disabled
  end

  it "renders disabled input field if user has no permission on attribute" do
    expect(subject).to have_selector('input#group_test_readonly[type="text"]')
    expect(subject.find("input#group_test_readonly")).to be_disabled
  end

  it "renders disabled enum select if user has no permission on attribute" do
    expect(subject).to have_selector('select#group_enum_readonly option[value="the_only_option"]',
      text: "The only option")
    expect(subject.find("select#group_enum_readonly")).to be_disabled
  end
end
