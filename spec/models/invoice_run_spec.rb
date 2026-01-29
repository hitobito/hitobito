# == Schema Information
#
# Table name: invoice_runs
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
#  index_invoice_runs_on_creator_id                     (creator_id)
#  index_invoice_runs_on_group_id                       (group_id)
#  index_invoice_runs_on_receiver_type_and_receiver_id  (receiver_type,receiver_id)
#

require "spec_helper"

describe InvoiceRun do
  let(:list) { mailing_lists(:leaders) }
  let(:people_filter) { nil }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  describe "recipients" do
    let(:leader) { people(:top_leader) }
    let(:member) { people(:bottom_member) }

    it "reads people from recipients when mailing list" do
      subject.recipient_source = list
      list.subscriptions.first.update!(role_types: [Group::TopGroup::Leader])
      expect(list.people).to be_present
      expect(subject.recipients(person)).to eq [leader]
    end

    it "reads people from recipients when people filter" do
      subject.group = group
      subject.creator_id = leader.id
      subject.recipient_source = InvoiceRuns::RecipientSourceBuilder.new({ids: [member.id].join(",")},
        group).recipient_source
      expect(subject.recipients(leader)).to eq [member]
    end

    it "reads people from recipients when event participations filter" do
      subject.recipient_source = Event::ParticipationsFilter.new(event: events(:top_course))
      expect(subject.recipients(leader)).to eq [member]
    end
  end

  describe "recipient_source" do
    it "accepts recipient_source as id and type" do
      Subscription.create!(mailing_list: list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])
      subject.attributes = {recipient_source_type: "MailingList", recipient_source_id: list.id}
      expect(subject.recipients(person).count).to eq 1
    end

    it "accepts mailing list as recipient_source" do
      subject.attributes = {title: :test, recipient_source: list}
      expect(subject).to be_valid
    end

    it "accepts people_filter as recipient_source" do
      subject.attributes = {title: :test, recipient_source: PeopleFilter.new}
      expect(subject).to be_valid
    end

    it "does not accept group as recipient_source" do
      subject.attributes = {title: :test, recipient_source: group}
      expect(subject).not_to be_valid
    end
  end

  it "#update_paid updates payment informations" do
    subject.update(group: group, title: :title, recipient_source: PeopleFilter.new)

    invoice = subject.invoices.create!(title: :title, recipient: person, total: 10, group: group)
    subject.invoices.create!(title: :title, recipient: other_person, total: 20, group: group)
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
