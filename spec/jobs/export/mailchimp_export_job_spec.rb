require 'spec_helper'

describe Export::MailchimpExportJob do
  let(:group)     { groups(:bottom_layer_one) }
  let(:user)      { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }

  subject { Export::MailchimpExportJob.new(group.id) }

  it "subscribes submitted group's people to the group's mailchimp list."
  it "deletes group's mailchimp list's subscribers if they are no longer in the group"
end
