#  Copyright (c) 2018, Grünliberale Partei Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Synchronize::Mailchimp::Result do
  def response(total:, finished:, failed:)
    {
      "total_operations" => total,
      "finished_operations" => finished,
      "errored_operations" => failed,
    }
  end

  context "unchanged state" do
    it "if operations are empty" do
      expect(subject.state).to eq :unchanged
    end
  end

  context "success state" do
    it "if single operation finished without error" do
      subject.track(:subscribed, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :success
    end

    it "if both operations finished without error" do
      subject.track(:subscribed, response(total: 1, finished: 1, failed: 0))
      subject.track(:deleted, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :success
    end
  end

  context "failed state" do
    it "if single operation did not finish" do
      subject.track(:subscribed, response(total: 1, finished: 0, failed: 0))
      expect(subject.state).to eq :failed
    end

    it "if single operation did not succeed" do
      subject.track(:subscribed, response(total: 1, finished: 1, failed: 1))
      expect(subject.state).to eq :failed
    end

    it "if both operations did not finish" do
      subject.track(:subscribed, response(total: 1, finished: 0, failed: 0))
      subject.track(:deleted, response(total: 1, finished: 0, failed: 0))
      expect(subject.state).to eq :failed
    end

    it "if both operations did not succeed" do
      subject.track(:subscribed, response(total: 1, finished: 1, failed: 1))
      subject.track(:deleted, response(total: 1, finished: 1, failed: 1))
      expect(subject.state).to eq :failed
    end
  end

  context "partial state" do
    it "if single operation had error" do
      subject.track(:subscribed, response(total: 2, finished: 2, failed: 1))
      expect(subject.state).to eq :partial
    end

    it "if one of two operations had error" do
      subject.track(:subscribed, response(total: 2, finished: 2, failed: 1))
      subject.track(:deleted, response(total: 1, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end

    it "if single operation did not finish error" do
      subject.track(:subscribed, response(total: 2, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end

    it "if one of two operations did not finish error" do
      subject.track(:subscribed, response(total: 1, finished: 1, failed: 0))
      subject.track(:deleted, response(total: 2, finished: 1, failed: 0))
      expect(subject.state).to eq :partial
    end
  end
end
