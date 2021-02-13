# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require "spec_helper"

describe MailingListsController, type: :controller do
  let(:group) { groups(:top_layer) }
  let(:top_leader) { people(:top_leader) }

  def scope_params
    {group_id: group.id}
  end

  let(:test_entry) { mailing_lists(:leaders) }
  let(:test_entry_attrs) do
    {name: "Test mailing list",
     description: "Bla bla bla",
     publisher: "Me & You",
     mail_name: "tester",
     subscribable: true,
     subscribers_may_post: false,
     anyone_may_post: false}
  end

  before do
    sign_in(people(:top_leader))
  end

  include_examples "crud controller"

  context "show" do
    it "renders json" do
      get :show, params: {group_id: group.id, id: test_entry.id}, format: :json
      json = JSON.parse(response.body).deep_symbolize_keys
      mailing_list = json[:mailing_lists].first
      expect(mailing_list).to eq({
        id: test_entry.id.to_s,
        type: "mailing_lists",
        name: "Leaders",
        description: nil,
        publisher: nil,
        mail_name: "leaders",
        additional_sender: nil,
        subscribable: true,
        subscribers_may_post: false,
        anyone_may_post: false,
        preferred_labels: [],
        delivery_report: false,
        main_email: false,
        links: {group: group.id.to_s}
      })
    end
  end
end
