require 'spec_helper'

describe MailchimpExportsController do
  let(:group) { groups(:top_group) }

  it "runs a delayed job." do
    expect do
      get :new, group_id: group, format: :js
    end.to change(Delayed::Job, :count).by(1)
  end
end
