# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleController do

  let(:top_leader) { people(:top_leader) }
  let(:group) { groups(:top_group) }

  context 'as top leader' do

    before { sign_in(top_leader) }

    context 'GET index' do

      before do
        @tg_member = Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person
        Fabricate(:phone_number, contactable: @tg_member, number: '123', label: 'Privat', public: true)
        Fabricate(:phone_number, contactable: @tg_member, number: '456', label: 'Mobile', public: false)
        Fabricate(:social_account, contactable: @tg_member, name: 'facefoo', label: 'Facebook', public: true)
        Fabricate(:social_account, contactable: @tg_member, name: 'skypefoo', label: 'Skype', public: false)
        Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one), person: @tg_member)
        @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

        @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

        @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        @tg_member.update_attributes(first_name: 'Al', last_name: 'Zoe', nickname: 'al', town: 'Eye', zip_code: '8000')
      end

      context 'sorting' do
        before do
          top_leader.update_attributes(first_name: 'Joe', last_name: 'Smith', nickname: 'js', town: 'Stoke', address: 'Howard Street', zip_code: '9000')
          @tg_extern.update_attributes(first_name: '', last_name: 'Bundy', nickname: '', town: '', address: '', zip_code: '')
        end

        let(:role_type_ids) { [Role::External.id, Group::TopGroup::Leader.id, Group::TopGroup::Member.id].join('-') }


        context 'default sort' do
          it "sorts by name" do
            get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids
            assigns(:people).collect(&:id).should == [@tg_extern, top_leader,  @tg_member].collect(&:id)
          end

          it "people.default_sort setting can override it to sort by role" do
            Settings.people.stub(default_sort: 'role')
            get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids
            assigns(:people).collect(&:id).should == [top_leader,  @tg_member, @tg_extern].collect(&:id)
          end
        end

        it "sorts based on last_name" do
          get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: :last_name, sort_dir: :asc
          assigns(:people).collect(&:id).should == [@tg_extern, top_leader,  @tg_member].collect(&:id)
        end

        it "sorts based on roles" do
          get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: :roles, sort_dir: :asc
          assigns(:people).should == [top_leader,  @tg_member, @tg_extern]
        end

        %w(first_name nickname zip_code town).each do |attr|
          it "sorts based on #{attr}" do
            get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: attr, sort_dir: :asc
            assigns(:people).should == [@tg_member, top_leader,  @tg_extern]
          end
        end
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

        it 'renders email addresses with additional ones' do
          e1 = Fabricate(:additional_email, contactable: @tg_member, mailings: true)
          Fabricate(:additional_email, contactable: @tg_member, mailings: false)
          get :index, group_id: group, format: :email
          @response.body.should == "top_leader@example.com,#{@tg_member.email},#{e1.email}"
        end

        context :json do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, group_id: group, format: :json
            json = JSON.parse(@response.body)
            person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
            person['links']['roles'].should have(1).item
          end
        end
      end

      context 'layer' do
        let(:group) { groups(:bottom_layer_one) }

        context 'with layer full' do
          before { sign_in(@bl_leader) }

          it 'loads group members when no types given' do
            get :index, group_id: group, kind: 'layer'

            assigns(:people).collect(&:id).should =~
              [people(:bottom_member), @bl_leader].collect(&:id)
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

          context :json do
            render_views

            it 'renders json with only the one role in this group' do
              get :index, group_id: group,
                          kind: 'layer',
                          role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                          format: :json
              json = JSON.parse(@response.body)
              person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
              person['links']['roles'].should have(2).item
            end
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

          assigns(:people).collect(&:id).should =~ [@bg_leader, @tg_member, @tg_extern].collect(&:id)
        end

        context :json do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, group_id: group,
                        kind: 'deep',
                        role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                        format: :json
            json = JSON.parse(@response.body)
            person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
            person['links']['roles'].should have(2).item
          end
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

        it 'does not update password for other person' do
          encrypted = person.encrypted_password
          put :update, group_id: group.id,
                       id: person.id,
                       person: { password: 'yadayada', password_confirmation: 'yadayada' }
          person.reload.encrypted_password.should eq encrypted
        end

        it 'create new phone numbers' do
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: {
                                     '111' =>
                                       { number: '031 111 1111', label: 'Privat', public: 1 },
                                     '222' =>
                                       { number: '', label: 'Arbeit', public: 1 }  } }
            assigns(:person).should be_valid
          end.to change { PhoneNumber.count }.by(1)
          person.reload.phone_numbers.should have(1).item
          number = person.phone_numbers.first
          number.number.should eq '031 111 1111'
          number.label.should eq 'Privat'
          number.public.should be_true
        end

        it 'updates existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '031 111 2222', label: 'Privat', public: 0, id: n.id } } }
          end.not_to change { PhoneNumber.count }
          number = person.reload.phone_numbers.first
          number.number.should eq '031 111 2222'
          number.public.should be_false
        end

        it 'destroys existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '031 111 1111', label: 'Privat', public: 0, id: n.id, _destroy: true } } }
          end.to change { PhoneNumber.count }.by(-1)
          person.reload.phone_numbers.should be_blank
        end

        it 'destroys existing phone numbers when number is empty' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '   ', label: 'Privat', public: 0, id: n.id } } }
          end.to change { PhoneNumber.count }.by(-1)
          person.reload.phone_numbers.should be_blank
        end

        it 'create, update and destroys social accounts' do
          a1 = person.social_accounts.create!(name: 'Housi', label: 'Facebook', public: 0)
          a2 = person.social_accounts.create!(name: 'Hans', label: 'Skype', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   social_accounts_attributes: {
                                     a1.id.to_s => { id: a1.id,
                                                     name: 'Housi1',
                                                     label: 'Facebook',
                                                     public: 1 },
                                     a2.id.to_s => { id: a2.id, _destroy: true },
                                     '999' => { name: 'John',
                                                label: 'Twitter',
                                                public: 0 }, } }
            assigns(:person).should be_valid
          end.not_to change { SocialAccount.count }

          person.reload.social_accounts.should have(2).items
          fb = person.social_accounts.order(:label).first
          fb.label.should eq 'Facebook'
          fb.name.should eq 'Housi1'
          fb.public.should be_true
          tw = person.social_accounts.order(:label).second
          tw.label.should eq 'Twitter'
          tw.name.should eq 'John'
          tw.public.should be_false
        end

        it 'create, update and destroys additional emails' do
          a1 = person.additional_emails.create!(email: 'Housi@example.com', label: 'Arbeit', public: 0)
          a2 = person.additional_emails.create!(email: 'Hans@example.com', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   additional_emails_attributes: {
                                     a1.id.to_s => { id: a1.id,
                                                     email: 'Housi1@example.com',
                                                     label: 'Arbeit',
                                                     public: 1 },
                                     a2.id.to_s => { id: a2.id, _destroy: true },
                                     '998' => { email: ' ',
                                                label: 'Vater',
                                                public: 1 },
                                     '999' => { email: 'John@example.com',
                                                label: 'Mutter',
                                                public: 0 }, } }
            assigns(:person).should be_valid
          end.not_to change { AdditionalEmail.count }

          person.reload.additional_emails.should have(2).items
          a = person.additional_emails.order(:label).first
          a.label.should eq 'Arbeit'
          a.email.should eq 'Housi1@example.com'
          a.public.should be_true
          tw = person.additional_emails.order(:label).second
          tw.label.should eq 'Mutter'
          tw.email.should eq 'John@example.com'
          tw.public.should be_false
        end
      end
    end

    describe 'GET #show' do
      let(:gl) { qualification_kinds(:gl) }
      let(:sl) { qualification_kinds(:sl) }

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

      context 'qualifications' do
        before do
          @ql_gl = Fabricate(:qualification, person: top_leader, qualification_kind: gl, start_at: Time.zone.now)
          @ql_sl = Fabricate(:qualification, person: top_leader, qualification_kind: sl, start_at: Time.zone.now)
        end

        it 'preloads data for asides, ordered by finish_at' do
          get :show, group_id: group.id, id: people(:top_leader).id
          assigns(:qualifications).should eq [@ql_sl, @ql_gl]
        end
      end

      context 'without group' do
        context :html do
          it 'keeps flash' do
            get :show, id: top_leader.id
            should redirect_to(group_person_path(top_leader.primary_group_id, top_leader.id, format: :html))
          end
        end

        context :json do
          it 'redirects to json' do
            get :show, id: top_leader.id, format: :json
            should redirect_to(group_person_path(top_leader.primary_group_id, top_leader.id, format: :json))
          end
        end
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
        flash[:notice].should eq 'Login Informationen wurden verschickt.'
      end
    end

    describe 'PUT #primary_group' do
      it 'sets primary group' do
        put :primary_group, group_id: group, id: top_leader.id, primary_group_id: group.id, format: :js

        top_leader.reload.primary_group_id.should == group.id
        should render_template('primary_group')
      end
    end

  end

  context :json do
    render_views

    before do
      @public_number = Fabricate(:phone_number, contactable: top_leader, public: true)
      @private_number = Fabricate(:phone_number, contactable: top_leader, public: false)
      Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_two_one), person: top_leader)
    end

    context 'as self' do
      before { sign_in(top_leader) }

      it 'GET index contains current role and all data' do
        get :index, group_id: group.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        person['links']['phone_numbers'].should have(2).items
        person['links']['roles'].should have(1).item
      end

      it 'GET show contains all roles and all data' do
        get :show, group_id: group.id, id: top_leader.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        person['links']['phone_numbers'].should have(2).items
        person['links']['roles'].should have(2).items
      end
    end

    context 'with contact data' do

      let(:user) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
      before { sign_in(user) }

      it 'GET index contains only current roles and public data' do
        get :index, group_id: group.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        person['links']['phone_numbers'].should have(1).item
        person['links']['phone_numbers'].first.should eq(@public_number.id.to_s)
        person['links']['roles'].should have(1).item
      end

      it 'GET show contains only current roles and public data' do
        get :show, group_id: group.id, id: top_leader.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        person['links']['phone_numbers'].should have(1).item
        person['links']['phone_numbers'].first.should eq(@public_number.id.to_s)
        person['links']['roles'].should have(1).item
      end
    end
  end
  context 'as api user' do

    describe 'GET #show' do
      it 'redirects when token is nil' do
        get :show, group_id: group.id, id: top_leader.id, user_token: '', user_email: top_leader.email
        should redirect_to new_person_session_path
      end

      it 'redirects when token is invalid' do
        get :show, group_id: group.id, id: top_leader.id, user_token: 'yadayada', user_email: top_leader.email
        should redirect_to new_person_session_path
      end

      it 'shows page when token is valid' do
        top_leader.generate_authentication_token!
        get :show, group_id: group.id, id: top_leader.id, user_token: top_leader.authentication_token, user_email: top_leader.email
        should render_template('show')
      end

      it 'shows page when headers are valid' do
        top_leader.generate_authentication_token!
        @request.headers['X-User-Email'] = top_leader.email
        @request.headers['X-User-Token'] = top_leader.authentication_token
        get :show, group_id: group.id, id: top_leader.id
        should render_template('show')
      end
    end

  end
end
