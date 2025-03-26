# == Schema Information
#
# Table name: invoice_lists
#
#  id                    :bigint           not null, primary key
#  amount_paid           :decimal(15, 2)   default(0.0), not null
#  amount_total          :decimal(15, 2)   default(0.0), not null
#  invalid_recipient_ids :text
#  receiver_type         :string
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
  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  describe "::validations" do
    let(:item) { Fabricate.build(:invoice_item) }
    let(:invoice) { Fabricate.build(:invoice, invoice_items: [item]) }
    let(:invoice_list) { Fabricate.build(:invoice_list, receiver: group, invoice:) }

    it "is valid" do
      expect(invoice_list).to be_valid
    end

    it "is invalid if title is blank" do
      invoice_list.title = nil
      expect(invoice_list).not_to be_valid
      expect(invoice_list.errors.full_messages).to eq ["Titel muss ausgefüllt werden"]
    end

    it "is invalid if invoice items are empty" do
      invoice_list.invoice.invoice_items = []
      expect(invoice_list).not_to be_valid
      expect(invoice_list.errors.full_messages).to eq ["Rechnungsposten müssen vorhanden sein"]
    end

    describe "receivers" do
      it "is invalid if no receiver is present" do
        invoice_list.receiver = nil
        expect(invoice_list).not_to be_valid
        expect(invoice_list.errors.full_messages).to eq ["Empfänger muss ausgefüllt werden"]
      end

      it "accepts receiver from group" do
        invoice_list.receiver = groups(:top_group)
        expect(invoice_list).to be_valid
      end

      it "accepts receiver from mailing_list" do
        invoice_list.receiver = list
        list.subscriptions.create(subscriber: person)
        expect(invoice_list).to be_valid
      end

      it "accepts receiver via recipient_ids" do
        invoice_list.receiver = nil
        invoice_list.recipient_ids = "#{person.id}, #{other_person.id}"
        expect(invoice_list).to be_valid
      end
    end
  end

  describe "recipient_ids" do
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

    it "does default to empty array" do
      expect(subject.recipient_ids).to eq []
    end

    it "accepts recipient_ids as attributes" do
      subject.attributes = {recipient_ids: "#{person.id},#{other_person.id}"}
      expect(subject.recipient_ids_count).to eq 2
      expect(subject.first_recipient).to eq person
    end
  end

  it "accepts receiver as id and type" do
    Subscription.create!(mailing_list: list,
      subscriber: group,
      role_types: [Group::TopGroup::Leader])
    subject.attributes = {receiver_type: "MailingList", receiver_id: list.id}
    expect(subject.recipient_ids_count).to eq 1
    expect(subject.first_recipient).to eq person
  end

  it "accepts mailing list as receiver" do
    subject.attributes = {title: :test, receiver: list}
    expect(subject).to be_valid
  end

  it "accepts group as receiver" do
    subject.attributes = {title: :test, receiver: group}
    expect(subject).to be_valid
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
