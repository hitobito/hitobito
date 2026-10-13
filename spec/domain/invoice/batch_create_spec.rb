#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

require "spec_helper"

describe Invoice::BatchCreate do
  include ActiveJob::TestHelper

  let(:mailing_list) { mailing_lists(:leaders) }
  let(:group) { groups(:top_layer) }
  let(:person) { people(:top_leader) }
  let(:other_person) { people(:bottom_member) }

  context "#call" do
    it "creates invoices for abo" do
      Subscription.create!(mailing_list: mailing_list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])

      run = InvoiceRun.create!(recipient_source: mailing_list, group: group, title: :title)

      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
      invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
      run.invoice = invoice
      expect do
        Invoice::BatchCreate.call(run, person)
      end.to change { group.issued_invoices.count }.by(1)
        .and change { group.invoice_items.count }.by(2)
      expect(run.reload).to have(1).invoices
      expect(run.recipient_source).to eq mailing_list
      expect(run.recipients_total).to eq 1
      expect(run.recipients_paid).to eq 0
      expect(run.amount_total).to eq 2.5
      expect(run.amount_paid).to eq 0
    end

    it "creates invoices in recipient language" do
      Subscription.create!(mailing_list: mailing_list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])
      person_de = people(:top_leader)
      person_fr = Fabricate(Group::TopGroup::Leader.name, group: groups(:top_group)).person
      person_fr.update!(language: :fr)

      run = InvoiceRun.create!(recipient_source: mailing_list, group: group,
        title: "title", title_fr: "titre")

      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", name_fr: "crayons", unit_cost: 1.5)
      run.invoice = invoice
      expect do
        Invoice::BatchCreate.call(run, person)
      end.to change { group.issued_invoices.count }.by(2)
        .and change { group.invoice_items.count }.by(2)

      interesting_attributes = run.reload.invoices.map do |invoice|
        LocaleSetter.with_locale(person: invoice.recipient) do
          {
            recipient: invoice.recipient,
            title: invoice.title,
            item_name: invoice.invoice_items.first.name
          }
        end
      end
      expect(interesting_attributes).to match_array([{
        recipient: person_de,
        title: "title",
        item_name: "pens"
      }, {
        recipient: person_fr,
        title: "titre",
        item_name: "crayons"
      }])
    end

    it "creates invoices for people in group distinct people regardless of role count" do
      group = groups(:bottom_layer_one)
      group.issued_invoices.destroy_all

      # rubocop:todo Layout/LineLength
      Fabricate(Group::BottomLayer::Leader.sti_name.to_sym, person: other_person, group: group) # second role for other_person
      # rubocop:enable Layout/LineLength
      2.times do
        Fabricate(Group::BottomLayer::Member.sti_name.to_sym, group: group)
      end
      expect(group.roles.size).to eq(4)
      expect(group.people.size).to eq(4) # people relation goes via roles and are currently not distinct

      filter = PeopleFilter.create!(group: group, range: :group)
      run = InvoiceRun.create!(recipient_source: filter, group: group, title: :title)

      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
      invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
      run.invoice = invoice

      expect do
        Invoice::BatchCreate.call(run, person)
      end.to change { group.issued_invoices.count }.by(3)
        .and change { group.invoice_items.count }.by(6)
      expect(run.reload).to have(3).invoices
      expect(run.recipient_source).to eq filter
      expect(run.recipients_total).to eq 3
      expect(run.recipients_paid).to eq 0
      expect(run.amount_total).to eq 7.5
      expect(run.amount_paid).to eq 0
    end

    it "offloads to job when recipients exceed limit" do
      Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
      Subscription.create!(mailing_list: mailing_list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])

      run = InvoiceRun.create!(recipient_source: mailing_list, group: group, title: :title)

      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
      invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
      run.invoice = invoice

      expect do
        Invoice::BatchCreate.call(run, person, 1)
        Delayed::Job.last.payload_object.perform
      end.to change { group.issued_invoices.count }.by(2)
        .and change { group.invoice_items.count }.by(4)
      expect(run.reload).to have(2).invoices
      expect(run.recipient_source).to eq mailing_list
      expect(run.recipients_total).to eq 2
      expect(run.recipients_paid).to eq 0
      expect(run.amount_total).to eq 5
      expect(run.amount_paid).to eq 0
      expect(run.recipients_processed).to eq 2
    end

    it "does not create any run model for recipient_ids" do
      run = InvoiceRun.new(group: group)
      run.recipient_source = InvoiceRuns::RecipientSourceBuilder.new({ids: [person.id, other_person.id].join(",")},
        group).recipient_source

      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
      invoice.invoice_items.build(name: "pins", unit_cost: 0.5, count: 2)
      run.invoice = invoice

      expect do
        Invoice::BatchCreate.call(run, person)
      end.to change { group.issued_invoices.count }.by(2)
        .and change { group.invoice_items.count }.by(4)
      expect(run).not_to be_persisted
    end

    it "does not rollback everything if any invoice save fails" do
      Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group))
      Subscription.create!(mailing_list: mailing_list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])

      run = InvoiceRun.new(recipient_source: mailing_list, group: group, title: :title)
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
      run.invoice = invoice

      allow_any_instance_of(Invoice).to receive(:save!).and_wrap_original do |m|
        @saved = @saved ? (raise ActiveRecord::RecordNotSaved.new("Test exception", nil)) : m.call
      end

      expect do
        Invoice::BatchCreate.new(run, person).call
      end.to change { group.issued_invoices.count }.by(1)
        .and change { group.invoice_items.count }.by(1)
      expect(run.invalid_recipient_ids).to have(1).item
    end

    it "does not rollback everything if any save fails due to errors while inserting ProcessedSubjects" do
      p2 = Fabricate(Group::TopGroup::Leader.sti_name, group: groups(:top_group)).person
      Subscription.create!(mailing_list: mailing_list,
        subscriber: group,
        role_types: [Group::TopGroup::Leader])
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, person:, group: groups(:bottom_layer_one))
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, person: p2, group: groups(:bottom_layer_one))

      period_invoice_template = Fabricate(:period_invoice_template)
      run = InvoiceRun.new(recipient_source: mailing_list, group: group, title: :title)
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: Group::BottomLayer::BasicPermissionsOnly.name
        })
      run.invoice = invoice

      recipients = run.recipients(person)
      template_item_id = period_invoice_template.items.first.id
      allow_any_instance_of(Invoice::RoleCountItem).to receive(:subjects).and_return([
        {subject_id: recipients.first.id, subject_type: "Person", template_item_id:, item_id: 12345},
        {subject_id: recipients.second.id, subject_type: "Person", template_item_id:, item_id: 12346}
      ])

      allow(InvoiceRun::ProcessedSubject).to receive(:insert_all!).and_wrap_original do |m, *args|
        @saved = @saved ? (raise ActiveRecord::RecordNotUnique.new("Test exception")) : m.call(*args)
      end

      expect do
        Invoice::BatchCreate.new(run, person).call
        expect(run.invalid_recipient_ids).to have(1).item
      end.to change { group.issued_invoices.count }.by(1)
        .and change { group.invoice_items.count }.by(1)
    end

    it "does not create period invoices with total cost zero" do
      period_invoice_template = Fabricate(:period_invoice_template)

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run")
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        unit_cost: 10,
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: Group::BottomLayer::BasicPermissionsOnly.name
        })
      run.invoice = invoice

      expect do
        Invoice::BatchCreate.new(run, person).call
      end.not_to change { group.issued_invoices.count }
      expect(run.invalid_recipient_ids).to have(0).items

      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: groups(:bottom_layer_one))
      expect do
        Invoice::BatchCreate.new(run, person).call
      end.to change { group.issued_invoices.count }.by(1)
      expect(run.invalid_recipient_ids).to have(0).items
    end

    it "documents the processed subjects" do
      period_invoice_template = Fabricate(:period_invoice_template)

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run")
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        unit_cost: 10,
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: Group::BottomLayer::BasicPermissionsOnly.name
        })
      run.invoice = invoice

      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: groups(:bottom_layer_one))
      expect do
        Invoice::BatchCreate.new(run, person).call
      end.to change { InvoiceRun::ProcessedSubject.count }.by(1)
    end

    it "documents the processed subjects of every item of the same template item" do
      period_invoice_template = Fabricate(:period_invoice_template)
      template_item_id = period_invoice_template.items.first.id

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run")
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      ["membership", "supplement"].each do |name|
        invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name:, unit_cost: 10,
          dynamic_cost_parameters: {
            template_item_id:,
            period_start_on: 1.year.ago,
            period_end_on: Time.zone.today,
            unit_cost: "10.00",
            role_types: Group::BottomLayer::BasicPermissionsOnly.name
          })
      end
      run.invoice = invoice

      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: groups(:bottom_layer_one))

      expect do
        Invoice::BatchCreate.new(run, person).call
      end.to change { InvoiceRun::ProcessedSubject.count }.by(2)
        .and change { group.issued_invoices.count }.by(1)

      expect(run.invalid_recipient_ids).to be_empty
      expect(group.issued_invoices.last.invoice_items).to have(2).items
    end

    it "records a subject once per item although the item counts it several times" do
      period_invoice_template = Fabricate(:period_invoice_template)
      counted = Fabricate(:person)
      Fabricate(Group::BottomLayer::Member.name, person: counted,
        group: groups(:bottom_layer_one))
      Fabricate(Group::BottomGroup::Member.name, person: counted,
        group: groups(:bottom_group_one_one))

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run")
      run.invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      run.invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        unit_cost: 10,
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: [Group::BottomLayer::Member.name, Group::BottomGroup::Member.name]
        })

      expect { Invoice::BatchCreate.new(run, person).call }
        .to change { group.issued_invoices.count }.by(1)
      expect(run.invalid_recipient_ids).to be_empty

      item = group.issued_invoices.find_by(recipient: groups(:bottom_layer_one)).invoice_items.sole
      expect(item.count).to eq 3
      expect(item.processed_subjects.pluck(:subject_id))
        .to contain_exactly(counted.id, people(:bottom_member).id)
    end

    it "charges a subject once per recipient, not once per invoice run" do
      period_invoice_template = Fabricate(:period_invoice_template)
      counted = Fabricate(:person)
      [groups(:bottom_layer_one), groups(:bottom_layer_two)].each do |recipient_group|
        Fabricate(Group::BottomLayer::BasicPermissionsOnly.name,
          person: counted, group: recipient_group)
      end

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run")
      run.invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      run.invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        unit_cost: 10,
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: Group::BottomLayer::BasicPermissionsOnly.name
        })

      expect { Invoice::BatchCreate.new(run, person).call }
        .to change { group.issued_invoices.count }.by(2)
        .and change { InvoiceRun::ProcessedSubject.count }.by(2)
      expect(run.invalid_recipient_ids).to be_empty
    end

    it "does not charge a subject again in a later run of the same template item" do
      period_invoice_template = Fabricate(:period_invoice_template)
      template_item_id = period_invoice_template.items.first.id
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: groups(:bottom_layer_one))

      build_run = lambda do
        InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
          period_invoice_template:, group:, title: "Run").tap do |run|
          run.invoice = Fabricate.build(:invoice, title: "invoice", group: group)
          ["membership", "supplement"].each do |name|
            run.invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name:,
              unit_cost: 10,
              dynamic_cost_parameters: {
                template_item_id:,
                period_start_on: 1.year.ago,
                period_end_on: Time.zone.today,
                unit_cost: "10.00",
                role_types: Group::BottomLayer::BasicPermissionsOnly.name
              })
          end
        end
      end

      expect { Invoice::BatchCreate.new(build_run.call, person).call }
        .to change { group.issued_invoices.count }.by(1)

      expect { Invoice::BatchCreate.new(build_run.call, person).call }
        .to not_change { group.issued_invoices.count }
        .and not_change { InvoiceRun::ProcessedSubject.count }
    end

    context "error reporting" do
      let(:run) do
        Subscription.create!(mailing_list:, subscriber: group,
          role_types: [Group::TopGroup::Leader])
        InvoiceRun.new(recipient_source: mailing_list, group: group, title: :title).tap do |run|
          run.invoice = Fabricate.build(:invoice, title: "invoice", group: group)
          run.invoice.invoice_items.build(name: "pens", unit_cost: 1.5)
        end
      end

      it "does not report a recipient whose own data prevents the invoice" do
        allow_any_instance_of(Invoice).to receive(:save!)
          .and_raise(ActiveRecord::RecordInvalid.new(Invoice.new))

        expect(Sentry).not_to receive(:capture_exception)

        expect { Invoice::BatchCreate.new(run, person).call }
          .to not_change { group.issued_invoices.count }
        expect(run.invalid_recipient_ids).to eq [person.id]
      end

      it "reports an unexpected error, which users cannot do anything about" do
        allow_any_instance_of(Invoice).to receive(:save!)
          .and_raise(ActiveRecord::StatementInvalid.new("boom"))

        expect(Sentry).to receive(:capture_exception)
          .with(kind_of(ActiveRecord::StatementInvalid), hash_including(:extra))

        expect { Invoice::BatchCreate.new(run, person).call }
          .to not_change { group.issued_invoices.count }
        expect(run.invalid_recipient_ids).to eq [person.id]
      end
    end

    it "generates the invoice in the recipient's language" do
      period_invoice_template = Fabricate(:period_invoice_template)

      run = InvoiceRun.new(recipient_source: period_invoice_template.recipient_source,
        period_invoice_template:, group:, title: "Run", title_fr: "FRun")
      invoice = Fabricate.build(:invoice, title: "invoice", group: group)
      invoice.invoice_items.build(type: Invoice::RoleCountItem.name, name: "membership",
        name_fr: "Fmembership", unit_cost: 10,
        dynamic_cost_parameters: {
          template_item_id: period_invoice_template.items.first.id,
          period_start_on: 1.year.ago,
          period_end_on: Time.zone.today,
          unit_cost: "10.00",
          role_types: Group::BottomLayer::BasicPermissionsOnly.name
        })
      run.invoice = invoice

      group_de = groups(:bottom_layer_one)
      group_fr = groups(:bottom_layer_two)
      group_fr.update!(language: :fr)
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: group_de)
      Fabricate(Group::BottomLayer::BasicPermissionsOnly.name, group: group_fr)

      expect do
        Invoice::BatchCreate.new(run, person).call
      end.to change { group.issued_invoices.count }.by(2)

      created_de, created_fr = Invoice.last(2)

      expect(created_de.title).to eq "Run"
      expect(created_de.recipient).to eq group_de
      expect(created_de.invoice_items.first.name).to eq "membership"

      LocaleSetter.with_locale(person: group_fr) do
        expect(created_fr.recipient).to eq group_fr
        expect(created_fr.title).to eq "FRun"
        expect(created_fr.invoice_items.first.name).to eq "Fmembership"
      end
    end
  end

  private

  def fabricate_donation(amount, received_at = 1.year.ago)
    invoice = Fabricate(:invoice, due_at: 10.days.from_now, creator: other_person, recipient: person, group: group,
      state: :payed)
    Payment.create!(amount: amount, received_at: received_at, invoice: invoice)
  end
end
