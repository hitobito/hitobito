#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe InvoiceRuns::RecipientSourceBuilder do
  let(:group) { groups(:top_layer) }

  subject(:recipient_source_builder) { described_class.new(params, group) }

  context "mailing_list" do
    let(:params) {
      ActionController::Parameters.new({invoice_run: {recipient_source_id: mailing_lists(:leaders).id,
                                                      recipient_source_type: "MailingList"}})
    }

    it "does return instance of mailing_list" do
      expect(recipient_source_builder.recipient_source).to eq mailing_lists(:leaders)
    end

    it "raises error when invalid recipient_source_type is passed" do
      params[:invoice_run][:recipient_source_type] = "SuperInvalidType"

      expect { recipient_source_builder.recipient_source }.to raise_error "Invalid recipient_source_type"
    end
  end

  context "people filter" do
    let(:params) { ActionController::Parameters.new({filter: {group_id: group.id, range: "group"}}) }

    it "builds filter without specific filter_chain specification" do
      expect(recipient_source_builder.recipient_source.range).to eq "group"
      expect(recipient_source_builder.recipient_source.group_id).to eq group.id
    end

    it "uses deep as default range" do
      params[:filter][:range] = ""
      expect(recipient_source_builder.recipient_source.range).to eq "deep"
    end

    it "builds filter_chain based on passed parameters" do
      params[:filter][:filters] = {attributes: {"0": {key: "first_name", constraint: "equal", value: "Lias"}}}
      expect(recipient_source_builder.recipient_source.filter_chain.to_params.to_s).to eq "{\"attributes\"=>" \
      "{\"0\"=>{\"key\"=>\"first_name\", \"constraint\"=>\"equal\", \"value\"=>\"Lias\"}}}"
    end

    it "uses group passed in filter_params instead of group itself" do
      params[:filter][:group_id] = groups(:bottom_layer_one).id
      expect(recipient_source_builder.recipient_source.group_id).to eq groups(:bottom_layer_one).id
    end
  end

  context "event filter" do
    let(:params) {
      ActionController::Parameters.new({filter: {event_id: events(:top_event).id, participant_type: nil}})
    }

    it "builds filter without specific participant_type specification" do
      expect(recipient_source_builder.recipient_source
                                     .to_params
                                     .to_s).to eq "{:filters=>{:participant_type=>nil}}"
    end

    it "builds filter with specific participant_type specification" do
      params[:filter][:filters] = {participant_type: "teamers"}
      expect(recipient_source_builder.recipient_source
                                     .to_params
                                     .to_s).to eq "{:filters=>{:participant_type=>\"teamers\"}}"
    end
  end

  context "ids" do
    let(:top_leader) { people(:top_leader) }
    let(:bottom_member) { people(:bottom_member) }

    let(:params) { ActionController::Parameters.new(ids: [top_leader.id, bottom_member.id].join(",")) }

    it "builds people_filter with attribute filter_chain" do
      expect(recipient_source_builder.recipient_source.filter_chain.to_params.to_s).to eq "{\"attributes\"=>" \
        "{\"0\"=>{\"constraint\"=>\"include\", \"key\"=>\"id\", \"value\"=>[572407901, 382461928]}}}"
    end
  end
end
