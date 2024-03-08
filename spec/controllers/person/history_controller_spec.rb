# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Person::HistoryController do

  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  describe 'GET #index' do

    context 'all roles' do

      it 'all group roles ordered by group and layer' do
        person = Fabricate(:person)
        r1 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one), person: person)
        r2 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one), person: person, created_at: Date.today - 3.years, deleted_at: Date.today - 2.years)
        r3 = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_two_one), person: person)
        r4 = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one_one), person: person)
        r5 = FutureRole.create!(group: groups(:bottom_group_two_one), convert_to: Group::BottomGroup::Member.name, person: person, created_at: Time.zone.now, convert_on: 10.days.from_now, delete_on: 20.days.from_now)
        r6 = FutureRole.create!(group: groups(:bottom_group_two_one), convert_to: Group::BottomGroup::Member.name, person: person, convert_on: 10.days.from_now)

        get :index, params: { group_id: groups(:bottom_group_one_one).id, id: person.id }

        expect(assigns(:roles)).to eq([r1, r4, r3])
        expect(assigns(:inactive_roles)).to eq([r2])
        expect(assigns(:future_roles)).to eq([r5, r6])
      end
    end


    context 'qualifications' do
      render_views

      let(:body) { Capybara::Node::Simple.new(response.body) }
      let(:sl_leader) { qualification_kinds(:sl_leader) }
      let(:gl) { qualification_kinds(:gl) }

      it 'does not render qualifications if no qualifications exist' do
        get :index, params: { group_id: groups(:top_group).id, id: top_leader.id }
        expect(body).not_to have_css 'h2.mt-4', text: 'Qualifikationen'
      end

      it 'lists and marks first qualifications of kind' do
        Fabricate(:qualification, person: top_leader, qualification_kind: gl, start_at: 30.months.ago, finish_at: 1.year.ago.to_date)
        Fabricate(:qualification, person: top_leader, qualification_kind: sl_leader, start_at: 1.week.from_now)

        get :index, params: { group_id: groups(:top_group).id, id: top_leader.id }
        expect(body).to have_css 'h2.mt-4', text: 'Qualifikationen'
        expect(body).to have_css 'tbody td strong', text: sl_leader.to_s
        expect(body).to have_css 'tbody td', text: gl.to_s
        expect(body).not_to have_css 'tbody td strong', text: gl.to_s
      end
    end

  end

end
