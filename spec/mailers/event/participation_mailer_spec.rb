# encoding: UTF-8
require "spec_helper"

describe Event::ParticipationMailer do
  describe "created" do
    let(:person) { people(:top_leader) }
    let(:participation) { Fabricate(:event_participation) }
    let(:mail) { Event::ParticipationMailer.created(person, participation) }
    let(:body) { Capybara::Node::Simple.new(mail.body) }
    let(:participation_url) { event_participation_path(participation.event, participation)}

    it "renders the headers" do
      mail.subject.should eq "Du wurdest zu einem Event hinzugefügt"
      mail.to.should eq(["top_leader@example.com"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.should include "Hallo Top Leader!"
      mail.body.should include participation_url
    end
  end

end
