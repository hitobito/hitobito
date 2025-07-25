# frozen_string_literal: true

#  Copyright (c) 2012-2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                               :integer          not null, primary key
#  applicant_count                  :integer          default(0)
#  application_closing_at           :date
#  application_conditions           :text
#  application_opening_at           :date
#  applications_cancelable          :boolean          default(FALSE), not null
#  automatic_assignment             :boolean          default(FALSE), not null
#  cost                             :string
#  description                      :text
#  display_booking_info             :boolean          default(TRUE), not null
#  external_applications            :boolean          default(FALSE)
#  globally_visible                 :boolean
#  hidden_contact_attrs             :text
#  location                         :text
#  maximum_participants             :integer
#  minimum_participants             :integer
#  motto                            :string
#  name                             :string
#  notify_contact_on_participations :boolean          default(FALSE), not null
#  number                           :string
#  participant_count                :integer          default(0)
#  participations_visible           :boolean          default(FALSE), not null
#  priorization                     :boolean          default(FALSE), not null
#  required_contact_attrs           :text
#  requires_approval                :boolean          default(FALSE), not null
#  search_column                    :tsvector
#  shared_access_token              :string
#  signature                        :boolean
#  signature_confirmation           :boolean
#  signature_confirmation_text      :string
#  state                            :string(60)
#  teamer_count                     :integer          default(0)
#  training_days                    :decimal(5, 2)
#  type                             :string
#  waiting_list                     :boolean          default(TRUE), not null
#  created_at                       :datetime
#  updated_at                       :datetime
#  application_contact_id           :integer
#  contact_id                       :integer
#  creator_id                       :integer
#  kind_id                          :integer
#  updater_id                       :integer
#
# Indexes
#
#  events_search_column_gin_idx         (search_column) USING gin
#  index_events_on_kind_id              (kind_id)
#  index_events_on_shared_access_token  (shared_access_token)
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

    its(:qualification_date) { should == Date.new(2011, 2, 20) }

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

    after { Event::Course.used_attributes += [:kind_id] }

    it "creates course" do
      Event::Course.create!(groups: [groups(:top_group)],
        name: "test",
        dates_attributes: [{start_at: Time.zone.now}])
    end

    it "renders label_detail" do
      events(:top_course).update(kind_id: nil, number: 123)
      expect(events(:top_course).label_detail).to eq "123 Top"
    end

    describe "required_attrs" do
      subject(:required_attrs) { events(:top_course).required_attrs }

      it "is empty when kind_id is not used" do
        expect(required_attrs).to be_empty
      end

      it "contains kind_id if kind_id is used" do
        Event::Course.used_attributes += [:kind_id]
        expect(required_attrs).to eq [:kind_id]
      end
    end
  end

  it "sets signature to true when signature confirmation is required" do
    course = Event::Course.new(signature_confirmation: true)
    expect(course.signature).to be_falsy
    expect(course.signature_confirmation).to be_truthy
    course.valid?

    expect(course.signature).to be_truthy
    expect(course.signature_confirmation).to be_truthy
  end

  describe "#duplicate" do
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

  it "makes participations visible to all participants by default" do
    is_expected.to be_participations_visible
  end

  describe "#minimum_age" do
    subject(:course) { described_class.new }

    it "is nil if no kind is set" do
      expect(course.minimum_age).to be_nil
    end

    it "is read from kind if kind has value set" do
      course.kind = Event::Kind.new(minimum_age: 2)
      expect(course.minimum_age).to eq 2
    end
  end

  describe "#qualifications_visible?" do
    subject(:course) { Fabricate.build(:course) }

    it "is true if kind is qualifiying and qualification_date is yesterday" do
      course.dates.build(start_at: 1.day.ago)
      expect(course.qualifications_visible?).to be_truthy
    end

    it "is false if kind is not qualifiying" do
      course.kind = event_kinds(:old)
      course.dates.build(start_at: 1.day.ago)

      expect(course.qualifications_visible?).to be_falsy
    end

    it "is false if qualification date is today" do
      course.dates.build(start_at: 0.days.ago)
      expect(course.qualifications_visible?).to be_falsy
    end
  end
end
