#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "contactable/_contact_data.html.haml" do
  let(:group) { groups(:top_layer) }
  let(:current_user) { people(:top_leader) }

  subject { Capybara::Node::Simple.new(@rendered) }

  before do
    group.assign_attributes(address: "foo", town: "bar", zip_code: 123, country: "ch")
    allow(view).to receive_messages(contactable: GroupDecorator.decorate(group), only_public: false, postal: true)
  end

  context "group" do
    before { render }

    it "displays group info" do
      is_expected.to have_content("foo")
      is_expected.to have_content("bar")
      is_expected.to have_content("123")
      is_expected.not_to have_content("ch")
    end
  end

  context "group.contact" do
    before do
      current_user.assign_attributes(address: "asdf", town: "fdas", zip_code: 321, country: "AT")
      group.contact = current_user
      group.save
      render
    end

    it "displays contact info" do
      is_expected.to have_content("asdf")
      is_expected.to have_content("fdas")
      is_expected.to have_content("321")
      is_expected.to have_content("Österreich")
    end
  end
end
