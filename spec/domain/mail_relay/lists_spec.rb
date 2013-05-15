require 'spec_helper'

describe MailRelay::Lists do

  let(:message) do
    mail = Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'regular.eml')))
    mail.header['X-Envelope-To'] = nil
    mail.header['X-Envelope-To'] = list.mail_name
    mail.from = from
    mail
  end


  let(:bll)  { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
  let(:bgl1) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person }
  let(:bgl2) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two)).person }
  let(:ind)  { Fabricate(:person) }

  let(:list) { mailing_lists(:leaders) }

  let(:subscribers) { [ind, bll, bgl1] }

  subject { MailRelay::Lists.new(message) }

  context "#mailing_list" do
    let(:from) { people(:top_leader).email }
    its(:envelope_receiver_name) { should == list.mail_name }
    its(:mailing_list) { should == list }
    it { should be_relay_address }
  end

  context "receivers with empty email" do
    let(:from) { people(:top_leader).email }
    before do
      ind.email = ''
      ind.save!
      sub = list.subscriptions.new
      sub.subscriber = ind
      sub.save!

      subscribers
    end

    its(:receivers) { should =~ [bll, bgl1].collect(&:email) }
  end

  context "list admin" do
    let(:from) { people(:top_leader).email }

    before { create_individual_subscribers }

    it { should be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == people(:top_leader) }
    its(:receivers) { should =~ subscribers.collect(&:email) }

    it "relays" do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
    end
  end

  context "additional sender" do
    let(:from) { 'news@example.com' }

    before { create_individual_subscribers }
    before { list.update_column(:additional_sender, from) }

    it { should be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should be_nil }
    its(:receivers) { should =~ subscribers.collect(&:email) }

    it "relays" do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
    end
  end


  context "list member" do
    let(:from) { bgl1.email }

    context "may post" do
      before { create_individual_subscribers }
      before { list.update_column(:subscribers_may_post, true) }

      it { should be_sender_allowed }
      its(:sender_email) { should == from }
      its(:sender) { should == bgl1 }
      its(:receivers) { should =~ subscribers.collect(&:email) }

      it "relays" do
        expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

        last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
      end
    end

    context "may not post" do
      before { create_individual_subscribers }
      before { list.update_column(:subscribers_may_post, false) }

      it { should_not be_sender_allowed }
      its(:sender_email) { should == from }
      its(:sender) { should == bgl1 }

      it "rejects" do
        expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

        last_email.smtp_envelope_to.should == [from]
        last_email.body.should =~ /nicht berechtigt/
      end
    end
  end

  context "excluded person" do
    let(:from) { bgl2.email }

    before { create_individual_subscribers }
    before { list.update_column(:subscribers_may_post, true) }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == bgl2 }

    it "rejects" do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context "anybody" do
    let(:from) { people(:bottom_member).email }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == people(:bottom_member) }

    it "rejects" do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context "foreign" do
    let(:from) { 'anybody@example.com' }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }

    it "rejects" do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context "anonymous" do
    let(:from) { nil }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }

    it "does not relay" do
      expect { subject.relay }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context "non existing list" do
    let(:from) { people(:top_leader).email }
    before { message.header['X-Envelope-To'] = 'foo' }

    it { should_not be_relay_address }

    it "does not relay" do
      expect { subject.relay }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  def create_individual_subscribers
    # single subscription
    sub = list.subscriptions.new
    sub.subscriber = ind
    sub.save!
    # excluded subscription
    sub = list.subscriptions.new
    sub.subscriber = bgl2
    sub.excluded = true
    sub.save!

    # create people
    subscribers
  end
end
