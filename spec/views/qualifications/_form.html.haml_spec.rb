#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "qualifications/_form.html.haml" do
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }

  before do
    qualification = person.qualifications.build
    assign(:group, group)
    assign(:person, person)
    path_args = [group, person, qualification]
    allow(view).to receive_messages(parents: [group, person], entry: qualification, path_args: path_args)
  end

  subject { Capybara::Node::Simple.new(rendered) }

  it "translates form fields" do
    render
    is_expected.to have_content "Qualifikation"
    is_expected.to have_content "Seit"
  end
end
