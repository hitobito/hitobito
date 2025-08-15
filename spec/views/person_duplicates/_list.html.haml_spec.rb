#  Copyright (c) 2012-2025, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "person_duplicates/_list.html.haml" do
  let(:current_user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:list) { mailing_lists(:leaders) }

  before do
    assign(:group, group)
    allow(view).to receive(:entries).and_return(PersonDuplicate.none.page(1))
    # allow_any_instance_of(MailingListsHelper).to receive(:current_user).and_return(person)
  end

  subject(:dom) { Capybara::Node::Simple.new(render) }

  it "renders subscribe button if permitted" do
    puts dom.native
  end
end
