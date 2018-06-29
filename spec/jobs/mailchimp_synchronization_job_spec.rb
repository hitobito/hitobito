require 'spec_helper'

describe MailchimpSynchronizationJob do
  let(:group)     { groups(:bottom_layer_one) }
  let(:user)      { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }

  subject { Export::MailchimpSynchronizationJob.new(group.id) }

  it "subscribes people on the submitted mailing list to it's mailchimp's counterpart."
  it "deletes people not on the submitted mailing list from it's mailchimp's counterpart."
end
