# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleController do

  before { sign_in(top_leader) }

  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_group) }

  context 'GET index' do

    before do
      @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
      Fabricate(:phone_number, contactable: @tg_member, number: '123', label: 'Privat', public: true)
      Fabricate(:phone_number, contactable: @tg_member, number: '456', label: 'Mobile', public: false)
      Fabricate(:social_account, contactable: @tg_member, name: 'facefoo', label: 'Facebook', public: true)
      Fabricate(:social_account, contactable: @tg_member, name: 'skypefoo', label: 'Skype', public: false)
      @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

      @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
      @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

      @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
      @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
    end

    context 'group' do
      it 'loads all members of a group' do
        get :index, group_id: group

        assigns(:people).collect(&:id).should =~ [top_leader, @tg_member].collect(&:id)
      end

      it 'loads externs of a group when type given' do
        get :index, group_id: group, role_type_ids: [Role::External.id].join('-')

        assigns(:people).collect(&:id).should =~ [@tg_extern].collect(&:id)
      end

      it 'loads selected roles of a group when types given' do
        get :index, group_id: group, role_type_ids: [Role::External.id, Group::TopGroup::Member.id].join('-')

        assigns(:people).collect(&:id).should =~ [@tg_member, @tg_extern].collect(&:id)
      end

      it 'generates pdf labels' do
        get :index, group_id: group, label_format_id: label_formats(:standard).id, format: :pdf

        @response.content_type.should == 'application/pdf'
        people(:top_leader).reload.last_label_format.should == label_formats(:standard)
      end

      it 'exports address csv files' do
        get :index, group_id: group, format: :csv

        @response.content_type.should == 'text/csv'
        @response.body.should =~ /^Vorname;Nachname;.*Privat/
        @response.body.should =~ /^Top;Leader;.*/
        @response.body.should =~ /123/
        @response.body.should_not =~ /skypefoo/
        @response.body.should_not =~ /Zusätzliche Angaben/
        @response.body.should_not =~ /Mobile/
      end

      it 'exports full csv files' do
        get :index, group_id: group, details: true, format: :csv

        @response.content_type.should == 'text/csv'
        @response.body.should =~ /^Vorname;Nachname;.*;Zusätzliche Angaben;.*Privat;.*Mobile;.*Facebook;.*Skype/
        @response.body.should =~ /^Top;Leader;.*;bla bla/
        @response.body.should =~ /123;456;.*facefoo;skypefoo/
      end

      it 'renders email addresses' do
        get :index, group_id: group, format: :email
        @response.content_type.should == 'text/plain'
        @response.body.should == "top_leader@example.com,#{@tg_member.email}"
      end
    end

    context 'layer' do
      let(:group) { groups(:bottom_layer_one) }

      context 'with layer full' do
        before { sign_in(@bl_leader) }

        it 'loads group members when no types given' do
          get :index, group_id: group, kind: 'layer'

          assigns(:people).collect(&:id).should =~ [people(:bottom_member), @bl_leader].collect(&:id)
        end

        it 'loads selected roles of a group when types given' do
          get :index, group_id: group,
                      role_type_ids: [Group::BottomGroup::Member.id, Role::External.id].join('-'),
                      kind: 'layer'

          assigns(:people).collect(&:id).should =~ [@bg_member, @bl_extern].collect(&:id)
        end

        it 'exports full csv when types given and ability exists' do
          get :index, group_id: group,
                      role_type_ids: [Group::BottomGroup::Member.id, Role::External.id].join('-'),
                      kind: 'layer',
                      details: true,
                      format: :csv

          @response.content_type.should == 'text/csv'
          @response.body.should =~ /^Vorname;Nachname;.*Zusätzliche Angaben/
        end
      end

      context 'with contact data' do
        before { sign_in(@tg_member) }

        it 'exports only address csv when types given and no ability exists' do
          get :index, group_id: group,
                      role_type_ids: [Group::BottomLayer::Leader.id, Group::BottomLayer::Member.id].join('-'),
                      kind: 'layer',
                      details: true,
                      format: :csv

          @response.content_type.should == 'text/csv'
          @response.body.should =~ /^Vorname;Nachname;.*/
          @response.body.should_not =~ /Zusätzliche Angaben/
          @response.body.split("\n").should have(2).items
        end
      end
    end

    context 'deep' do
      let(:group) { groups(:top_layer) }

      it 'loads group members when no types are given' do
        get :index, group_id: group, kind: 'deep'

        assigns(:people).collect(&:id).should =~ []
      end

      it 'loads selected roles of a group when types given' do
        get :index, group_id: group,
                    role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                    kind: 'deep'

        assigns(:people).collect(&:id).should =~ [@bg_leader, @tg_extern].collect(&:id)
      end
    end
  end

  context 'GET query' do
    it 'queries all people' do
      Fabricate(:person, first_name: 'Pascal')
      Fabricate(:person, last_name: 'Opassum')
      Fabricate(:person, last_name: 'Anything')
      get :query, q: 'pas'

      response.body.should =~ /Pascal/
      response.body.should =~ /Opassum/
    end
  end

  context 'POST create' do
    it 'creates new person with role' do
      post :create, group_id: group.id,
                    role: { type: 'Group::TopGroup::Member', group_id: group.id },
                    person: { last_name: 'Foo', email: 'foo@example.com' }

      person = assigns(:person)
      should redirect_to(group_person_path(group, person))
      person.should be_persisted
      person.email.should == 'foo@example.com'
      person.roles.should have(1).item
      person.roles.first.should be_persisted
      last_email.should_not be_present
    end


    it 'does not create person with not allowed role' do
      user = Fabricate(Group::BottomGroup::Leader.name.to_s, group: groups(:bottom_group_one_one))
      sign_in(user.person)

      expect do
        post :create, group_id: group.id,
                      role: { type: 'Group::TopGroup::Member', group_id: group.id },
                      person: { last_name: 'Foo', email: 'foo@example.com' }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'PUT update' do
    let(:person) { people(:bottom_member) }
    let(:group) { person.groups.first }

    it 'as admin updates email with password' do
      put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
      assigns(:person).email.should == 'foo@example.com'
    end

    context 'as bottom leader' do
      before { sign_in(Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person) }

      it 'updates email for person in one group' do
        person.update_column(:encrypted_password, nil)
        put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
        assigns(:person).email.should == 'foo@example.com'
      end

      it 'does not update email for person in multiple groups' do
        Fabricate(Group::BottomLayer::Member.name.to_sym, person: person, group: groups(:bottom_layer_two))
        put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
        assigns(:person).email.should == 'bottom_member@example.com'
      end

    end
  end

  describe 'GET #show' do
    let(:gl) { qualification_kinds(:gl) }
    let(:sl) { qualification_kinds(:sl) }
    before do
      @ql_gl = Fabricate(:qualification, person: top_leader, qualification_kind: gl, finish_at: 1.year.from_now)
      @ql_sl = Fabricate(:qualification, person: top_leader, qualification_kind: sl, finish_at: Time.zone.now)
    end

    it 'preloads data for asides, ordered by finish_at' do
      get :show, group_id: group.id, id: people(:top_leader).id
      assigns(:qualifications).should eq [@ql_sl, @ql_gl]
    end
  end

  describe 'POST #send_password_instructions' do
    let(:person) { people(:bottom_member) }

    it 'does not send instructions for self' do
      expect do
        expect do
          post :send_password_instructions, group_id: group.id, id: top_leader.id, format: :js
        end.to raise_error(CanCan::AccessDenied)
      end.not_to change { Delayed::Job.count }
    end

    it 'sends password instructions' do
      expect do
        post :send_password_instructions, group_id: groups(:bottom_layer_one).id, id: person.id, format: :js
      end.to change { Delayed::Job.count }.by(1)
      flash[:notice].should eq  'Login Informationen wurden verschickt.'
    end
  end

  describe 'GET show' do

    it 'generates pdf labels' do
      get :show, group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id, format: :pdf

      @response.content_type.should == 'application/pdf'
      people(:top_leader).reload.last_label_format.should == label_formats(:standard)
    end

    it 'exports csv file' do
      get :show, group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id, format: :csv

      @response.content_type.should == 'text/csv'
      @response.body.should =~ /^Vorname;Nachname/
      @response.body.should =~ /^Top;Leader/
    end

  end

  describe 'PUT primary_group' do
    it 'sets primary group' do
      put :primary_group, group_id: group, id: top_leader.id, primary_group_id: group.id, format: :js

      top_leader.reload.primary_group_id.should == group.id
      should render_template('primary_group')
    end
  end

end
