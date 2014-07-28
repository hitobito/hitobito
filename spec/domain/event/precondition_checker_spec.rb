# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe Event::PreconditionChecker do
  let(:course) { events(:top_course) }
  let(:person) { people(:top_leader) }

  let(:course_start_at) { course.start_date }

  def preconditions
    course.kind.qualification_kinds('precondition', 'participant')
  end

  subject { Event::PreconditionChecker.new(course, person) }
  before do
    course.kind.event_kind_qualification_kinds.
      where(category: 'precondition', role: 'participant').
      destroy_all
  end

  describe 'defaults' do
    its(:course_minimum_age) { should be_blank }
    its(:valid?) { should be_true }
  end

  describe 'minimum age person' do
    before { course.kind.minimum_age = 16 }
    let(:too_young_error) { 'Altersgrenze von 16 unterschritten.' }

    context 'has no birthday' do
      its(:valid?) { should be_false }
      its('errors_text.last') { should eq too_young_error }
    end

    context 'is younger than 16' do
      before { person.birthday = (course_start_at.beginning_of_year - 15.years) }
      its(:valid?) { should be_false }
      its('errors_text.last') { should eq too_young_error }
    end

    context 'is 16 years during course' do
      before { person.birthday = course_start_at - 16.years }
      its(:valid?) { should be_true }
      its('errors') { should be_empty }
    end

    context 'is 16 years end of year' do
      before { person.birthday = course_start_at.end_of_year - 16.years }
      its(:valid?) { should be_true }
      its('errors') { should be_empty }
    end
  end

  describe 'qualification' do
    let(:sl) { qualification_kinds(:sl) }
    let(:qualifications) { person.qualifications }

    before do
      course.kind.event_kind_qualification_kinds.create!(qualification_kind_id: sl.id,
                                                         category: 'precondition',
                                                         role: 'participant')
    end

    context "person without 'super lead'" do
      its(:valid?) { should be_false }
      its('errors_text.last') { should =~ /Super Lead/ }
    end

    context "person with expired 'super lead'" do
      before { qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: expired_date) }
      its(:valid?) { should be_false }

      context "'super lead kind' reactivateable in range" do
        before { sl.update_attribute(:reactivateable, Date.today.year - expired_date.year) }
        its(:valid?) { should be_true }
      end
    end

    context "person with valid 'super lead'" do
      before { qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: valid_date) }
      its(:valid?) { should be_true }
      its(:errors_text) { should == [] }
    end

    context "person with expired and valid 'super lead'" do
      before do
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: expired_date)
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: valid_date)
      end
      its(:valid?) { should be_true }
      its(:errors_text) { should == [] }
    end

    context "person with unlimited 'super lead'" do
      before do
        sl.update_attribute(:validity, nil)
        qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: course_start_at - 1.day)
      end

      its(:valid?) { should be_true }
    end

    context 'multiple preconditions' do
      let(:gl) { qualification_kinds(:gl) }

      before do
        course.kind.event_kind_qualification_kinds.create!(qualification_kind_id: gl.id,
                                                           category: 'precondition',
                                                           role: 'participant')
      end
      its('errors_text.last') { should =~ /Qualifikationen fehlen: Super Lead, Group Lead$/ }

      context 'missing only one' do
        before { qualifications << Fabricate(:qualification, qualification_kind: sl, start_at: valid_date) }

        its(:valid?) { should be_false }
        its('errors_text.last') { should =~ /Qualifikationen fehlen: Group Lead$/ }
      end
    end

    def valid_date
      (course_start_at - sl.validity.years)
    end

    def expired_date
      (valid_date - 1.year).end_of_year
    end
  end
end
