#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Synchronize::Mailchimp::Result do
  let(:payload) { {} }

  def response(total:, finished:, failed:, results: [])
    {
      total_operations: total,
      finished_operations: finished,
      errored_operations: failed,
      operation_results: results
    }
  end

  context "unchanged state" do
    it "if operations are empty" do
      expect(subject.state).to eq :unchanged
    end
  end

  context "success state" do
    it "if single operation finished without error" do
      subject.track(:subscribed, payload, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :success
    end

    it "if both operations finished without error" do
      subject.track(:subscribed, payload, response(total: 1, finished: 1, failed: 0))
      subject.track(:deleted, payload, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :success
    end
  end

  context "failed state" do
    it "if single operation did not finish" do
      subject.track(:subscribed, payload, response(total: 1, finished: 0, failed: 0))
      expect(subject.state).to eq :failed
    end

    it "if single operation did not succeed" do
      subject.track(:subscribed, payload, response(total: 1, finished: 1, failed: 1))
      expect(subject.state).to eq :failed
    end

    it "if both operations did not finish" do
      subject.track(:subscribed, payload, response(total: 1, finished: 0, failed: 0))
      subject.track(:deleted, payload, response(total: 1, finished: 0, failed: 0))
      expect(subject.state).to eq :failed
    end

    it "if both operations did not succeed" do
      subject.track(:subscribed, payload, response(total: 1, finished: 1, failed: 1))
      subject.track(:deleted, payload, response(total: 1, finished: 1, failed: 1))
      expect(subject.state).to eq :failed
    end
  end

  context "partial state" do
    it "if single operation had error" do
      subject.track(:subscribed, payload, response(total: 2, finished: 2, failed: 1))
      expect(subject.state).to eq :partial
    end

    it "if one of two operations had error" do
      subject.track(:subscribed, payload, response(total: 2, finished: 2, failed: 1))
      subject.track(:deleted, payload, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end

    it "if single operation did not finish error" do
      subject.track(:subscribed, payload, response(total: 2, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end

    it "if one of two operations did not finish error" do
      subject.track(:subscribed, payload, response(total: 1, finished: 1, failed: 0))
      subject.track(:deleted, payload, response(total: 2, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end
  end

  it "does track forgottten emails" do
    results = [
      {title: "Deleted", detail: "test1@example.com was permanently deleted", status: 400},
      {title: "Deleted", detail: "test2@example.com was permanently deleted", status: 400},
      {title: "Member In Compliance State",
       detail: "test3@example.com is already a list member in compliance state " \
         "due to unsubscribe, bounce, or compliance review.",
       status: 400}
    ]
    subject.track(:subscribe_members, payload, response(total: 3, finished: 0, failed: 3, results:))
    expect(subject.state).to eq :failed
    expect(subject.forgotten_emails).to eq %w[test1@example.com test2@example.com test3@example.com]
  end

  it "does add operation results if failed" do
    payload = [
      {method: "PUT", path: "lists/0190dd036d/members/be8cf7f7ec1922469a77b47826f908ae",
       # rubocop:todo Layout/LineLength
       body: "{\"email_address\":\"jamie-rosenbauer@hitobito.com\",\"merge_fields\":{\"FNAME\":\"Jamie\",\"LNAME\":\"Rosenbauer\",\"GENDER\":\"z\"},\"language\":\"fr\"}"}
      # rubocop:enable Layout/LineLength
    ]
    results = [
      {title: "Invalid Resource",
       detail: "Your merge fields were invalid.",
       status: 400,
       errors: [{field: "GENDER", message: "Value must be one of: m, w,  (not z)"}]}
    ]
    subject.track(:add_members, payload, response(total: 1, finished: 1, failed: 1, results:))
    expect(subject.state).to eq :failed
    expect(subject.data.dig(:add_members, :failed).last[0][:operation]).to eq payload[0]
  end
end
