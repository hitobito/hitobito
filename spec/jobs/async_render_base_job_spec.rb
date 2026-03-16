#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

class RandomJob < AsyncRenderBaseJob
  def partial_name
    "random/even/more/random"
  end

  def data
    {random: "random"}
  end

  def set_locale
  end
end

describe AsyncRenderBaseJob do
  let(:user) { people(:top_leader) }
  let(:target_dom_id) { "some-target-id" }
  let(:options) { {make_job_fast: true} }

  let(:base_job) { described_class.new(user.id, target_dom_id, options) }
  let(:random_job) { RandomJob.new(user.id, target_dom_id, options) }

  describe "#initialize" do
    it "assigns parameters" do
      expect(base_job.user_id).to eq(user.id)
      expect(base_job.target_dom_id).to eq(target_dom_id)
      expect(base_job.options).to eq(options)
    end
  end

  describe "#perform" do
    let(:rendered_html) { "<div id='some-target-id'>Important Information</div>" }

    before do
      allow(ApplicationController).to receive(:render).and_return(rendered_html)
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    end

    it "renders the partial and broadcasts it" do
      random_job.perform

      expect(ApplicationController).to have_received(:render).with(
        partial: "random/even/more/random",
        locals: {data: {random: "random"}, target_dom_id: target_dom_id}
      )

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "user_#{user.id}_async_updates",
        target: target_dom_id,
        html: rendered_html
      )
    end
  end

  describe "abstract methods" do
    it "raises a NotImplementedError for #partial_name" do
      expect {
        base_job.send(:partial_name)
      }.to raise_error(NotImplementedError, "Subclasses must implement #partial_name")
    end

    it "raises a NotImplementedError for #data" do
      expect { base_job.send(:data) }.to raise_error(NotImplementedError, "Subclasses must implement #data")
    end
  end

  describe "#channel_name" do
    it "generates the correct channel name based on user_id" do
      expect(base_job.send(:channel_name)).to eq("user_#{user.id}_async_updates")
    end
  end
end
