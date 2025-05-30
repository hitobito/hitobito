# == Schema Information
#
# Table name: invoice_lists
#
#  id                    :bigint           not null, primary key
#  amount_paid           :decimal(15, 2)   default(0.0), not null
#  amount_total          :decimal(15, 2)   default(0.0), not null
#  invalid_recipient_ids :text
#  receiver_type         :string
#  receivers             :text
#  recipients_paid       :integer          default(0), not null
#  recipients_processed  :integer          default(0), not null
#  recipients_total      :integer          default(0), not null
#  title                 :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  creator_id            :bigint
#  group_id              :bigint
#  receiver_id           :bigint
#
# Indexes
#
#  index_invoice_lists_on_creator_id                     (creator_id)
#  index_invoice_lists_on_group_id                       (group_id)
#  index_invoice_lists_on_receiver_type_and_receiver_id  (receiver_type,receiver_id)
#

require "spec_helper"

describe InvoiceList do
  let(:list) { mailing_lists(:leaders) }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  describe "recipient_ids" do
    describe "writing" do
      it "accepts an array" do
        subject.recipient_ids = [1, 2, 3]
        expect(subject.recipient_ids).to eq [1, 2, 3]
      end

      it "accepts comma separated value string array" do
        subject.recipient_ids = "1,2,3"
        expect(subject.recipient_ids).to eq [1, 2, 3]
      end

      it "accepts space separated value string array" do
        subject.recipient_ids = "1 2 3"
        expect(subject.recipient_ids).to eq [1, 2, 3]
      end

      it "ignores invalid ids" do
        subject.recipient_ids = "1,asdf,3"
        expect(subject.recipient_ids).to eq [1, 3]
      end

      it "does default to empty array for nil" do
        subject.recipient_ids = nil
        expect(subject.recipient_ids).to eq []
      end

      it "accepts recipient_ids as attributes" do
        subject.attributes = {recipient_ids: "#{person.id},#{other_person.id}"}
        expect(subject.recipient_ids_count).to eq 2
      end
    end
  end

  describe "receivers" do
    let(:leader) { people(:top_leader) }
    let(:member) { people(:bottom_member) }

    it "reads people from receiver" do
      subject.receiver = list
      list.subscriptions.first.update!(role_types: [Group::TopGroup::Leader])
      expect(list.people).to be_present
      expect(subject.recipients).to eq [leader]
    end

    it "reads people from receivers" do
      subject.receivers = [member.id]
      expect(subject.recipients).to eq [member]
    end

    it "prefers people from receiver model over what is set on receivers" do
      subject.receivers = [member.id]
      subject.receiver = list
      list.subscriptions.first.update!(role_types: [Group::TopGroup::Leader])
      expect(subject.recipients).to eq [leader]
    end
  end

  describe "receiver" do
    it "accepts receiver as id and type" do
      Subscription.create!(mailing_list: list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])
      subject.attributes = {receiver_type: "MailingList", receiver_id: list.id}
      expect(subject.recipient_ids_count).to eq 1
    end

    it "accepts mailing list as receiver" do
      subject.attributes = {title: :test, receiver: list}
      expect(subject).to be_valid
    end

    it "accepts group as receiver" do
      subject.attributes = {title: :test, receiver: group}
      expect(subject).to be_valid
    end
  end

  describe "receivers" do
    it "accepts receivers as integers" do
      subject.receivers = [1, 2]
      expect(subject.receivers).to eq [
        InvoiceLists::Receiver.new(id: 1),
        InvoiceLists::Receiver.new(id: 2)
      ]
    end

    it "accepts receivers as models" do
      subject.receivers = [InvoiceLists::Receiver.new(id: 1), InvoiceLists::Receiver.new(id: 2)]
      expect(subject.receivers).to eq [
        InvoiceLists::Receiver.new(id: 1),
        InvoiceLists::Receiver.new(id: 2)
      ]
    end
  end

  it "#update_paid updates payment informations" do
    subject.update(group: group, title: :title)

    invoice = subject.invoices.create!(title: :title, recipient_id: person.id, total: 10, group: group)
    subject.invoices.create!(title: :title, recipient_id: other_person.id, total: 20, group: group)
    invoice.payments.create!(amount: 10)

    expect do
      subject.update_paid
    end.to change(subject, :amount_paid).from(0).to(10)
      .and change(subject, :recipients_paid).from(0).to(1)
  end

  it "#to_s returns title" do
    subject.title = "A big invoice"
    expect(subject.to_s).to eq "A big invoice"
  end
end
