# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe MailRelay::Lists do

  let(:message) do
    mail = Mail.new(File.read(Rails.root.join('spec', 'support', 'email', 'regular.eml')))
    mail.header['X-Envelope-To'] = nil
    mail.header['X-Envelope-To'] = envelope_to
    mail.from = from
    mail
  end

  let(:envelope_to) { list.mail_name }

  let(:bll)  { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
  let(:bgl1) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person }
  let(:bgl2) { Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_two)).person }
  let(:ind)  { Fabricate(:person) }

  let(:list) { mailing_lists(:leaders) }

  let(:subscribers) { [ind, bll, bgl1] }

  let(:relay) { MailRelay::Lists.new(message) }
  subject { relay }

  context '#mailing_list' do
    let(:from) { people(:top_leader).email }
    its(:envelope_receiver_name) { should == list.mail_name }
    its(:mailing_list) { should == list }
    it { should be_relay_address }
  end

  context '#receivers' do
    let(:from) { people(:top_leader).email }
    subject { relay.receivers }

    before do
      sub = list.subscriptions.new
      sub.subscriber = ind
      sub.save!

      subscribers
    end

    context 'with empty email' do
      before do
        ind.email = ''
        ind.save!
      end

      it { should =~ [bll, bgl1].collect(&:email) }
    end

    context 'with additional emails' do

      let!(:e1) { Fabricate(:additional_email, contactable: ind, mailings: true) }
      let!(:e2) { Fabricate(:additional_email, contactable: ind, mailings: false) }

      it { should =~ [ind,bll, bgl1].collect(&:email) + [e1.email]}
    end
  end

  context 'list admin' do
    let(:from) { people(:top_leader).email }

    before { create_individual_subscribers }

    it { should be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == people(:top_leader) }
    its(:receivers) { should =~ subscribers.collect(&:email) }

    it 'relays' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
    end
  end

  context 'additional sender' do
    let(:from) { 'news@example.com' }

    before { create_individual_subscribers }
    before { list.update_column(:additional_sender, from) }

    it { should be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should be_nil }
    its(:receivers) { should =~ subscribers.collect(&:email) }

    it 'relays' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
    end
  end

  context 'list member' do
    let(:from) { bgl1.email }

    context 'may post' do
      before { create_individual_subscribers }
      before { list.update_column(:subscribers_may_post, true) }

      it { should be_sender_allowed }
      its(:sender_email) { should == from }
      its(:sender) { should == bgl1 }
      its(:receivers) { should =~ subscribers.collect(&:email) }

      it 'relays' do
        expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

        last_email.smtp_envelope_to.should =~ subscribers.collect(&:email)
      end
    end

    context 'may not post' do
      before { create_individual_subscribers }
      before { list.update_column(:subscribers_may_post, false) }

      it { should_not be_sender_allowed }
      its(:sender_email) { should == from }
      its(:sender) { should == bgl1 }

      it 'rejects' do
        expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

        last_email.smtp_envelope_to.should == [from]
        last_email.from.should == ["#{list.mail_name}@localhost"]
        last_email.body.should =~ /nicht berechtigt/
      end
    end

  end

  context 'excluded person' do
    let(:from) { bgl2.email }

    before { create_individual_subscribers }
    before { list.update_column(:subscribers_may_post, true) }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == bgl2 }

    it 'rejects' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.from.should == ["#{list.mail_name}@localhost"]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context 'anybody' do
    let(:from) { people(:bottom_member).email }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }
    its(:sender) { should == people(:bottom_member) }

    it 'rejects' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.from.should == ["#{list.mail_name}@localhost"]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context 'foreign' do
    let(:from) { 'anybody@example.com' }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }

    it 'rejects' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == [from]
      last_email.from.should == ["#{list.mail_name}@localhost"]
      last_email.body.should =~ /nicht berechtigt/
    end
  end

  context 'anonymous' do
    let(:from) { nil }

    it { should_not be_sender_allowed }
    its(:sender_email) { should == from }

    it 'does not relay' do
      expect { subject.relay }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context 'empty reply to' do

    let(:message) do
      message = <<-END
        Return-Path: <d.k@autoreply.example.com>
        From: d.k@autoreply.example.com
        Reply-To: <>
        To: \"hitobito\" <noreply@hitobito.ch>

        Hallo
        Vielen Dank f=FCr ihre Interesse.
      END

      mail = Mail.new(message)
      mail.header['X-Envelope-To'] = envelope_to
      mail
    end

    let(:from) { '<>' }

    it { should_not be_sender_allowed }

    it 'rejects without email' do
      expect { subject.relay }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context 'bounce' do
    let(:from) { 'deamon@example.com' }

    let(:envelope_to) { "#{list.mail_name}-bounces+test=example.com" }

    its(:sender_email) { should == from }

    it 'forwards bounce message' do
      expect { subject.relay }.to change { ActionMailer::Base.deliveries.size }.by(1)

      last_email.smtp_envelope_to.should == ['test@example.com']
      last_email.smtp_envelope_from.should == "#{list.mail_name}-bounces@localhost"
      last_email.from.should == [from]
    end
  end

  context 'emails to app sender' do
    let(:from) { 'deamon@example.com' }

    let(:envelope_to) { MailRelay::Lists.app_sender_name }

    before { Fabricate(:mailing_list, group: list.group, mail_name: MailRelay::Lists.app_sender_name) }

    its(:sender_email) { should == from }

    it 'does not reject messages' do
      expect { subject.relay }.not_to change { ActionMailer::Base.deliveries.size }
    end
  end

  context 'non existing list' do
    let(:from) { people(:top_leader).email }
    let(:envelope_to) { 'foo' }

    it { should_not be_relay_address }

    it 'does not relay' do
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
