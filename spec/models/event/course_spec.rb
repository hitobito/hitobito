# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
# == Schema Information
#
# Table name: events
#
#  id                          :integer          not null, primary key
#  type                        :string
#  name                        :string           not null
#  number                      :string
#  motto                       :string
#  cost                        :string
#  maximum_participants        :integer
#  contact_id                  :integer
#  description                 :text
#  location                    :text
#  application_opening_at      :date
#  application_closing_at      :date
#  application_conditions      :text
#  kind_id                     :integer
#  state                       :string(60)
#  priorization                :boolean          default(FALSE), not null
#  requires_approval           :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  participant_count           :integer          default(0)
#  application_contact_id      :integer
#  external_applications       :boolean          default(FALSE)
#  applicant_count             :integer          default(0)
#  teamer_count                :integer          default(0)
#  signature                   :boolean
#  signature_confirmation      :boolean
#  signature_confirmation_text :string
#  creator_id                  :integer
#  updater_id                  :integer
#

require "spec_helper"

describe Event::Course do
  subject do
    Fabricate(:course, groups: [groups(:top_group)])
  end

  its(:qualification_date) { should == Date.new(2012, 5, 11) }

  context "#qualification_date" do
    before do
      subject.dates.destroy_all
      add_date("2011-01-20")
      add_date("2011-02-15")
      add_date("2011-01-02")
    end

    its(:qualification_date) { should == Date.new(2011, 02, 20) }

    def add_date(start_at, event = subject)
      start_at = Time.zone.parse(start_at)
      event.dates.create(start_at: start_at, finish_at: start_at + 5.days)
    end
  end

  context "multiple start_at" do
    before { subject.dates.create(start_at: Date.new(2012, 5, 14)) }

    its(:qualification_date) { should == Date.new(2012, 5, 14) }
  end

  context "without event_kind" do
    before { Event::Course.used_attributes -= [:kind_id] }

    it "creates course" do
      Event::Course.create!(groups: [groups(:top_group)],
                            name: "test",
                            dates_attributes: [{start_at: Time.zone.now}])
    end

    it "renders label_detail" do
      events(:top_course).update(kind_id: nil, number: 123)
      expect(events(:top_course).label_detail).to eq "123 Top"
    end

    after { Event::Course.used_attributes += [:kind_id] }
  end

  it "sets signtuare to true when signature confirmation is required" do
    course = Event::Course.new(signature_confirmation: true)
    expect(course.signature).to be_falsy
    expect(course.signature_confirmation).to be_truthy
    course.valid?

    expect(course.signature).to be_truthy
    expect(course.signature_confirmation).to be_truthy
  end

  context "#duplicate" do
    let(:event) { events(:top_course) }

    it "resets participant counts" do
      d = event.duplicate
      expect(d.participant_count).to eq(0)
      expect(d.teamer_count).to eq(0)
      expect(d.applicant_count).to eq(0)
    end

    it "resets state" do
      d = event.duplicate
      expect(d.state).to be_nil
    end

    it "keeps empty questions" do
      event.questions = []
      d = event.duplicate
      expect(d.application_questions.size).to eq(0)
    end

    it "copies existing questions" do
      d = event.duplicate
      expect do
        d.dates << Fabricate.build(:event_date, event: d)
        d.save!
      end.to change { Event::Question.count }.by(3)
    end
  end
end
