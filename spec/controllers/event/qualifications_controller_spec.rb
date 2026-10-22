#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Event::QualificationsController do
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:slk))
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  let(:group) { event.groups.first }

  let!(:participant_1) { create_participation(Event::Course::Role::Participant, last_name: "BB") }
  let!(:participant_2) { create_participation(Event::Course::Role::Participant, last_name: "AA") }
  let!(:helper_1) { create_participation(Event::Role::Helper) }
  let!(:leader_1) { create_participation(Event::Role::Leader) }

  def create_participation(role, last_name: nil)
    participation = Fabricate(:event_participation, event: event, active: true)
    participation.person.update!(last_name: last_name)
    Fabricate(role.name.to_sym, participation: participation)
    participation.reload
  end

  before { sign_in(people(:top_leader)) }

  it "event kind has one qualification kind" do
    expect(event.kind.qualification_kinds("qualification", "participant")).to eq [qualification_kinds(:sl)]
  end

  describe "GET index" do
    context "entries" do
      before do
        get :index, params: {group_id: group.id, event_id: event.id}
      end

      it { expect(assigns(:participants).size).to eq(2) }
      it { expect(assigns(:leaders).size).to eq(1) }

      it "orders by name" do
        expect(assigns(:participants).pluck(:id)).to eq [participant_2.id, participant_1.id]
      end

      context "with qualifiable helpers" do
        around do |spec|
          previous = Event::Role::Helper.qualifiable
          Event::Role::Helper.qualifiable = true

          spec.run

          Event::Role::Helper.qualifiable = previous
        end

        it { expect(assigns(:participants).size).to eq(2) }
        it { expect(assigns(:leaders).size).to eq(2) }
      end
    end

    context "for regular event" do
      let(:event) { events(:top_event) }

      it "is not possible" do
        expect do
          get :index, params: {group_id: group.id, event_id: event.id}
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context "views" do
      render_views

      it "renders radio buttons per participation and comment field" do
        participant_1.update_columns(qualified: false, qualification_comment: "Zu wenig Praxis")
        get :index, params: {group_id: group.id, event_id: event.id}

        dom = Capybara::Node::Simple.new(response.body)
        row = dom.find("tr#event_participation_#{participant_1.id}")
        expect(row).to have_field("qualifications_#{participant_1.id}_qualified_false", type: "radio", checked: true)
        expect(row).to have_field("qualifications_#{participant_1.id}_qualified_true", type: "radio", checked: false)
        expect(row).to have_field("qualifications_#{participant_1.id}_qualified_", type: "radio", checked: false)
        expect(row).to have_field("qualifications[#{participant_1.id}][qualification_comment]", with: "Zu wenig Praxis")
      end

      it "preselects not assessed for new participations" do
        get :index, params: {group_id: group.id, event_id: event.id}

        dom = Capybara::Node::Simple.new(response.body)
        row = dom.find("tr#event_participation_#{participant_1.id}")
        expect(row).to have_field("qualifications_#{participant_1.id}_qualified_", type: "radio", checked: true)
      end
    end
  end

  describe "PUT update" do
    subject { obtained_qualifications }

    def submission(qualified, comment = nil)
      {qualified: qualified, qualification_comment: comment}
    end

    def update_with(submissions)
      put :update, params: {group_id: group.id, event_id: event.id, qualifications: submissions.transform_keys(&:id)}
    end

    context "passing" do
      context "with one existing qualifications" do
        before do
          qualification_kind_id = event.kind.qualification_kinds("qualification", "participant").first.id
          participant_1.person.qualifications.create!(qualification_kind_id: qualification_kind_id,
            start_at: start_at, qualified_at: start_at)
        end

        context "issued before qualification date" do
          let(:start_at) { event.qualification_date - 1.day }

          it "issues qualification" do
            expect do
              update_with(participant_1 => submission("true"))
            end.to change { Qualification.count }.by(1)
            expect(subject.size).to eq(1)
          end
        end

        context "issued on qualification date" do
          let(:start_at) { event.qualification_date }

          it "keeps existing qualification" do
            expect do
              update_with(participant_1 => submission("true"))
            end.not_to change { Qualification.count }
            expect(subject.size).to eq(1)
          end
        end
      end

      context "without existing qualifications for participant" do
        before { update_with(participant_1 => submission("true")) }

        it "has 1 item" do
          expect(subject.size).to eq(1)
        end

        it "marks participation as qualified" do
          expect(participant_1.reload.qualified).to be true
        end

        it "redirects with notice" do
          expect(response).to redirect_to(group_event_qualifications_path(group, event))
          expect(flash[:notice]).to be_present
        end
      end

      context "without existing qualifications for leader" do
        before { update_with(leader_1 => submission("true")) }

        it "should obtain a qualification" do
          obtained = obtained_qualifications(leader_1)
          expect(obtained.size).to eq(1)
        end
      end
    end

    context "not passing" do
      context "with one existing qualification" do
        before do
          qualification_kind_id = event.kind.qualification_kinds("qualification", "participant").first.id
          participant_1.person.qualifications.create!(qualification_kind_id: qualification_kind_id,
            start_at: event.qualification_date)
          participant_1.update_column(:qualified, true)
          update_with(participant_1 => submission("false", "Zu wenig Praxis"))
        end

        it "has no items" do
          expect(subject.size).to eq(0)
        end

        it "stores qualified false and comment" do
          participant_1.reload
          expect(participant_1.qualified).to be false
          expect(participant_1.qualification_comment).to eq "Zu wenig Praxis"
        end
      end

      context "without comment" do
        it "is accepted if comment is not required" do
          update_with(participant_1 => submission("false"))
          expect(participant_1.reload.qualified).to be false
          expect(response).to redirect_to(group_event_qualifications_path(group, event))
        end

        context "if comment is required" do
          before do
            allow(Settings.event.qualifications).to receive(:comment_required_if_not_qualified).and_return(true)
          end

          it "re-renders form with error and stores nothing" do
            update_with(participant_1 => submission("false"), participant_2 => submission("true"))

            expect(response).to have_http_status(:unprocessable_content)
            expect(response).to render_template(:index)
            expect(participant_1.reload.qualified).to be_nil
            expect(participant_2.reload.qualified).to be_nil
            expect(obtained_qualifications(participant_2)).to be_empty
          end

          it "is accepted with comment" do
            update_with(participant_1 => submission("false", "Abwesend"))
            expect(participant_1.reload.qualified).to be false
          end

          it "is not required for qualified participants" do
            update_with(participant_1 => submission("true"))
            expect(participant_1.reload.qualified).to be true
          end
        end
      end
    end

    context "not assessed" do
      before do
        qualification_kind_id = event.kind.qualification_kinds("qualification", "participant").first.id
        participant_1.person.qualifications.create!(qualification_kind_id: qualification_kind_id,
          start_at: event.qualification_date)
        participant_1.update_columns(qualified: true, qualification_comment: "Alt")
        update_with(participant_1 => submission(""))
      end

      it "resets qualified to nil and revokes qualification" do
        expect(participant_1.reload.qualified).to be_nil
        expect(subject.size).to eq(0)
      end
    end

    context "participations without submitted qualification" do
      it "are left untouched" do
        participant_2.update_column(:qualified, false)
        update_with(participant_1 => submission("true"))
        expect(participant_2.reload.qualified).to be false
      end
    end
  end

  def obtained_qualifications(participation = participant_1)
    role = (participation.roles.any? { |role| role.class.leader? }) ? "leader" : "participant"
    qualification_kinds = participation.event.kind.qualification_kinds(:qualification, role)
    participation.person.qualifications
      .where(qualified_at: participation.event.qualification_date)
      .where(qualification_kind_id: qualification_kinds.map(&:id)).to_a
  end
end
