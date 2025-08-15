#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventDecorator, :draper_with_helpers do
  include Rails.application.routes.url_helpers

  let(:event) { events(:top_course) }

  subject { EventDecorator.new(event) }

  its(:labeled_link) { is_expected.to match(/SLK TOP-007 Top/) }
  its(:labeled_link) { is_expected.to match(%r{<a href="/groups/#{event.group_ids.first}/events/#{event.id}">}) }

  its(:label_with_group) { is_expected.to eq("Top: Top Course (TOP-007)") }

  context "typeahead label" do
    subject { EventDecorator.new(event).as_typeahead[:label] }

    it { is_expected.to eq "#{event} (#{event.groups.first})" }

    context "multiple groups are joined and truncated" do
      before do
        event.groups += [groups(:top_group), groups(:bottom_layer_one), groups(:bottom_group_one_one),
          groups(:bottom_layer_two), groups(:bottom_group_two_one)]
      end

      it { is_expected.to eq "#{event} (Top, TopGroup, Bottom One...)" }
    end
  end

  describe "#dates" do
    before { event.dates.clear }

    it "joins multiple dates" do
      add_date(start_at: "2002-01-01")
      add_date(start_at: "2002-01-01")
      expect(subject.dates_info).to eq "Di 01.01.2002<br />Di 01.01.2002"
    end

    context "date objects" do
      it "start_at only" do
        add_date(start_at: "2002-01-01")
        expect(subject.dates_info).to eq "Di 01.01.2002"
      end

      it "start and finish" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-13")
        expect(subject.dates_info).to eq "Di 01.01.2002 - So 13.01.2002"
      end

      it "start and finish on same day" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-01")
        expect(subject.dates_info).to eq "Di 01.01.2002"
      end
    end

    context "time objects" do
      it "start_at only" do
        add_date(start_at: "2002-01-01 13:30")
        expect(subject.dates_info).to eq "Di 01.01.2002 13:30"
      end

      it "start and finish" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-13 15:30")
        expect(subject.dates_info).to eq "Di 01.01.2002 13:30 - So 13.01.2002 15:30"
      end

      it "start and finish on same day, start time" do
        add_date(start_at: "2002-01-01", finish_at: "2002-01-01 13:30")
        expect(subject.dates_info).to eq "Di 01.01.2002 00:00 - 13:30"
      end

      it "start and finish on same day, finish time" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 13:30")
        expect(subject.dates_info).to eq "Di 01.01.2002 13:30"
      end

      it "start and finish on same day, both times" do
        add_date(start_at: "2002-01-01 13:30", finish_at: "2002-01-01 15:30")
        expect(subject.dates_info).to eq "Di 01.01.2002 13:30 - 15:30"
      end
    end

    def add_date(date)
      %w[:start_at, :finish_at].each do |key|
        date[key] = parse(date[key]) if date.key?(key)
      end
      event.dates.build(date)
      event.save!
    end

    def parse(str)
      Time.zone.parse(str)
    end
  end

  context "qualification infos" do
    context "with qualifications and prolongations" do
      its(:issued_qualifications_info_for_leaders) do
        should == "Vergibt die Qualifikation Super Lead (for Leaders) unmittelbar per 01.03.2012 (letztes Kursdatum)."
      end

      its(:issued_qualifications_info_for_participants) do
        # rubocop:todo Layout/LineLength
        should == "Vergibt die Qualifikation Super Lead und verlängert existierende Qualifikationen Group Lead unmittelbar per 01.03.2012 (letztes Kursdatum)."
        # rubocop:enable Layout/LineLength
      end
    end

    context "only with qualifications" do
      before { event.kind = event_kinds(:glk) }

      its(:issued_qualifications_info_for_leaders) do
        should == "Vergibt die Qualifikation Group Lead (for Leaders) unmittelbar per 01.03.2012 (letztes Kursdatum)."
      end

      its(:issued_qualifications_info_for_participants) do
        should == "Vergibt die Qualifikation Group Lead unmittelbar per 01.03.2012 (letztes Kursdatum)."
      end
    end

    context "only with prolongations" do
      before { event.kind = event_kinds(:fk) }

      its(:issued_qualifications_info_for_leaders) do
        # rubocop:todo Layout/LineLength
        should == "Verlängert existierende Qualifikationen Group Lead (for Leaders), Super Lead (for Leaders) unmittelbar per 01.03.2012 (letztes Kursdatum)."
        # rubocop:enable Layout/LineLength
      end

      its(:issued_qualifications_info_for_participants) do
        # rubocop:todo Layout/LineLength
        should == "Verlängert existierende Qualifikationen Group Lead, Super Lead unmittelbar per 01.03.2012 (letztes Kursdatum)."
        # rubocop:enable Layout/LineLength
      end
    end

    context "without qualifications and prolongations" do
      before { event.kind = event_kinds(:old) }

      its(:issued_qualifications_info_for_leaders) do
        should == ""
      end

      its(:issued_qualifications_info_for_participants) do
        should == ""
      end
    end
  end

  context "external_application_link" do
    let(:group) { groups(:top_group) }

    subject { EventDecorator.new(event).external_application_link(group) }

    context "event does not support external applications" do
      before { event.update_column(:external_applications, false) }

      it { is_expected.to eq "nicht möglich" }
    end

    context "event supports external applications" do
      before { event.update_column(:external_applications, true) }

      it { is_expected.to match(/public_event/) }
    end
  end

  context "#complete_contact_attributes" do
    before { event.contact = people(:top_leader) }

    subject { EventDecorator.new(event).complete_contact_attributes }

    context "with every possible attribute" do
      it {
        # rubocop:todo Layout/LineLength
        is_expected.to eq "<strong>Top Leader</strong><p>Greatstreet 345<br />3456 Greattown</p><p><a href=\"mailto:top_leader@example.com\">top_leader@example.com</a></p>"
      }
      # rubocop:enable Layout/LineLength
    end

    context "with only name" do
      before { event.update!(visible_contact_attributes: ["name"]) }

      it { is_expected.to eq "<strong>Top Leader</strong>" }
    end

    context "contact person without email" do
      before { people(:top_leader).update_column(:email, nil) }

      it { is_expected.to eq "<strong>Top Leader</strong><p>Greatstreet 345<br />3456 Greattown</p>" }
    end
  end
end
