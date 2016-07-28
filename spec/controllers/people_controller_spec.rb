# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe PeopleController do

  before do
    PeopleRelation.kind_opposites['parent'] = 'child'
    PeopleRelation.kind_opposites['child'] = 'parent'
  end

  after do
    PeopleRelation.kind_opposites.clear
  end

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
            expect(assigns(:people).collect(&:id)).to eq([@tg_extern, top_leader,  @tg_member].collect(&:id))
          end

          it "people.default_sort setting can override it to sort by role" do
            allow(Settings.people).to receive_messages(default_sort: 'role')
            get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids
            expect(assigns(:people).collect(&:id)).to eq([top_leader,  @tg_member, @tg_extern].collect(&:id))
          end
        end

        it "sorts based on last_name" do
          get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: :last_name, sort_dir: :asc
          expect(assigns(:people).collect(&:id)).to eq([@tg_extern, top_leader,  @tg_member].collect(&:id))
        end

        it "sorts based on roles" do
          get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: :roles, sort_dir: :asc
          expect(assigns(:people)).to eq([top_leader,  @tg_member, @tg_extern])
        end

        %w(first_name nickname zip_code town).each do |attr|
          it "sorts based on #{attr}" do
            get :index, group_id: group, kind: 'layer', role_type_ids: role_type_ids, sort: attr, sort_dir: :asc
            expect(assigns(:people)).to eq([@tg_member, top_leader,  @tg_extern])
          end
        end
      end

      context 'group' do
        it 'loads all members of a group' do
          get :index, group_id: group

          expect(assigns(:people).collect(&:id)).to match_array([top_leader, @tg_member].collect(&:id))
          expect(assigns(:person_add_requests)).to eq([])
        end

        it 'loads externs of a group when type given' do
          get :index, group_id: group, role_type_ids: [Role::External.id].join('-')

          expect(assigns(:people).collect(&:id)).to match_array([@tg_extern].collect(&:id))
        end

        it 'loads selected roles of a group when types given' do
          get :index, group_id: group, role_type_ids: [Role::External.id, Group::TopGroup::Member.id].join('-')

          expect(assigns(:people).collect(&:id)).to match_array([@tg_member, @tg_extern].collect(&:id))
        end

        it 'loads pending person add requests' do
          r1 = Person::AddRequest::Group.create!(
                  person: Fabricate(:person),
                  requester: Fabricate(:person),
                  body: group,
                  role_type: group.class.role_types.first.sti_name)

          get :index, group_id: group.id

          expect(assigns(:person_add_requests)).to eq([r1])
        end

        context '.pdf' do
          it 'generates pdf labels' do
            expect(Person::CondensedContact).not_to receive(:condense_list)
            get :index, group_id: group, label_format_id: label_formats(:standard).id, format: :pdf

            expect(@response.content_type).to eq('application/pdf')
            expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
          end

          it 'generates condensed pdf labels' do
            expect(Person::CondensedContact).to receive(:condense_list).once.and_call_original
            get :index, group_id: group, label_format_id: label_formats(:standard).id, condense_labels: 'true', format: :pdf

            expect(@response.content_type).to eq('application/pdf')
            expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
          end
        end

        context '.csv' do
          it 'exports address csv files' do
            get :index, group_id: group, format: :csv

            expect(@response.content_type).to eq('text/csv')
            expect(@response.body).to match(/^Vorname;Nachname;.*Privat/)
            expect(@response.body).to match(/^Top;Leader;.*/)
            expect(@response.body).to match(/123/)
            expect(@response.body).not_to match(/skypefoo/)
            expect(@response.body).not_to match(/Zusätzliche Angaben/)
            expect(@response.body).not_to match(/Mobile/)
          end

          it 'exports full csv files' do
            get :index, group_id: group, details: true, format: :csv

            expect(@response.content_type).to eq('text/csv')
            expect(@response.body).to match(/^Vorname;Nachname;.*;Zusätzliche Angaben;.*Privat;.*Mobile;.*Facebook;.*Skype/)
            expect(@response.body).to match(/^Top;Leader;.*;bla bla/)
            expect(@response.body).to match(/123;456;.*facefoo;skypefoo/)
          end
        end

        context '.email' do
          it 'renders email addresses' do
            get :index, group_id: group, format: :email
            expect(@response.content_type).to eq('text/plain')
            expect(@response.body).to eq("top_leader@example.com,#{@tg_member.email}")
          end

          it 'renders email addresses with additional ones' do
            e1 = Fabricate(:additional_email, contactable: @tg_member, mailings: true)
            Fabricate(:additional_email, contactable: @tg_member, mailings: false)
            get :index, group_id: group, format: :email
            expect(@response.body).to eq("top_leader@example.com,#{@tg_member.email},#{e1.email}")
          end
        end

        context '.json' do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, group_id: group, format: :json
            json = JSON.parse(@response.body)
            person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
            expect(person['links']['roles'].size).to eq(1)
          end
        end
      end

      context 'layer' do
        let(:group) { groups(:bottom_layer_one) }

        context 'with layer and below full' do
          before { sign_in(@bl_leader) }

          it 'loads group members when no types given' do
            get :index, group_id: group, kind: 'layer'

            expect(assigns(:people).collect(&:id)).to match_array(
              [people(:bottom_member), @bl_leader].collect(&:id)
            )
          end

          it 'loads selected roles of a group when types given' do
            get :index, group_id: group,
                        role_type_ids: [Group::BottomGroup::Member.id, Role::External.id].join('-'),
                        kind: 'layer'

            expect(assigns(:people).collect(&:id)).to match_array([@bg_member, @bl_extern].collect(&:id))
          end

          it 'does not load pending person add requests' do
            r1 = Person::AddRequest::Group.create!(
              person: Fabricate(:person),
              requester: Fabricate(:person),
              body: group,
              role_type: group.class.role_types.first.sti_name)

            get :index, group_id: group.id, kind: 'layer'

            expect(assigns(:person_add_requests)).to be_nil
          end

          it 'exports full csv when types given and ability exists' do
            get :index, group_id: group,
                        role_type_ids: [Group::BottomGroup::Member.id, Role::External.id].join('-'),
                        kind: 'layer',
                        details: true,
                        format: :csv

            expect(@response.content_type).to eq('text/csv')
            expect(@response.body).to match(/^Vorname;Nachname;.*Zusätzliche Angaben/)
          end

          context 'json' do
            render_views

            it 'renders json with only the one role in this group' do
              get :index, group_id: group,
                          kind: 'layer',
                          role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                          format: :json
              json = JSON.parse(@response.body)
              person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
              expect(person['links']['roles'].size).to eq(2)
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

            expect(@response.content_type).to eq('text/csv')
            expect(@response.body).to match(/^Vorname;Nachname;.*/)
            expect(@response.body).not_to match(/Zusätzliche Angaben/)
            expect(@response.body.split("\n").size).to eq(2)
          end
        end
      end

      context 'deep' do
        let(:group) { groups(:top_layer) }

        it 'loads group members when no types are given' do
          get :index, group_id: group, kind: 'deep'

          expect(assigns(:people).collect(&:id)).to match_array([])
        end

        it 'loads selected roles of a group when types given' do
          get :index, group_id: group,
                      role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                      kind: 'deep'

          expect(assigns(:people).collect(&:id)).to match_array([@bg_leader, @tg_member, @tg_extern].collect(&:id))
        end

        context 'json' do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, group_id: group,
                        kind: 'deep',
                        role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-'),
                        format: :json
            json = JSON.parse(@response.body)
            person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
            expect(person['links']['roles'].size).to eq(2)
          end
        end
      end
    end

    context 'PUT update' do
      let(:person) { people(:bottom_member) }
      let(:group) { person.groups.first }

      it 'as admin updates email with password' do
        put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
        expect(assigns(:person).email).to eq('foo@example.com')
      end

      context 'as bottom leader' do
        before { sign_in(Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person) }

        it 'updates email for person in one group' do
          person.update_column(:encrypted_password, nil)
          put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
          expect(assigns(:person).email).to eq('foo@example.com')
        end

        it 'does not update email for person in multiple groups' do
          Fabricate(Group::BottomLayer::Member.name.to_sym, person: person, group: groups(:bottom_layer_two))
          put :update, group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' }
          expect(assigns(:person).email).to eq('bottom_member@example.com')
        end

        it 'does not update password for other person' do
          encrypted = person.encrypted_password
          put :update, group_id: group.id,
                       id: person.id,
                       person: { password: 'yadayada', password_confirmation: 'yadayada' }
          expect(person.reload.encrypted_password).to eq encrypted
        end

        it 'create new phone numbers' do
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: {
                                     '111' =>
                                       { number: '031 111 1111', translated_label: 'Privat', public: 1 },
                                     '222' =>
                                       { number: '', translated_label: 'Arbeit', public: 1 }  } }
            expect(assigns(:person)).to be_valid
          end.to change { PhoneNumber.count }.by(1)
          expect(person.reload.phone_numbers.size).to eq(1)
          number = person.phone_numbers.first
          expect(number.number).to eq '031 111 1111'
          expect(number.label).to eq 'Privat'
          expect(number.public).to be_truthy
        end

        it 'updates existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '031 111 2222', translated_label: 'Privat', public: 0, id: n.id } } }
          end.not_to change { PhoneNumber.count }
          number = person.reload.phone_numbers.first
          expect(number.number).to eq '031 111 2222'
          expect(number.public).to be_falsey
        end

        it 'updates existing phone numbers in other language' do
          @cached_locales = I18n.available_locales
          @cached_languages = Settings.application.languages
          Settings.application.languages = { de: 'Deutsch', fr: 'Français' }
          I18n.available_locales = Settings.application.languages.keys

          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Vater', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         locale: :fr,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '031 111 2222', translated_label: 'mère', public: 0, id: n.id } } }
          end.not_to change { PhoneNumber.count }

          I18n.available_locales = @cached_locales
          Settings.application.languages = @cached_languages
          I18n.locale = I18n.default_locale

          number = person.reload.phone_numbers.first
          expect(number.number).to eq '031 111 2222'
          expect(number.label).to eq 'Mutter'
          expect(number.public).to be_falsey
        end

        it 'destroys existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '031 111 1111', translated_label: 'Privat', public: 0, id: n.id, _destroy: true } } }
          end.to change { PhoneNumber.count }.by(-1)
          expect(person.reload.phone_numbers).to be_blank
        end

        it 'destroys existing phone numbers when number is empty' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   phone_numbers_attributes: { n.id.to_s =>
                                     { number: '   ', translated_label: 'Privat', public: 0, id: n.id } } }
          end.to change { PhoneNumber.count }.by(-1)
          expect(person.reload.phone_numbers).to be_blank
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
                                                     translated_label: 'Facebook',
                                                     public: 1 },
                                     a2.id.to_s => { id: a2.id, _destroy: true },
                                     '999' => { name: 'John',
                                                translated_label: 'Twitter',
                                                public: 0 }, } }
            expect(assigns(:person)).to be_valid
          end.not_to change { SocialAccount.count }

          accounts = person.reload.social_accounts.order(:label)
          expect(accounts.size).to eq(2)
          fb = accounts.first
          expect(fb.label).to eq 'Facebook'
          expect(fb.name).to eq 'Housi1'
          expect(fb.public).to be_truthy
          tw = accounts.second
          expect(tw.label).to eq 'Twitter'
          expect(tw.name).to eq 'John'
          expect(tw.public).to be_falsey
        end

        it 'create, update and destroys additional emails' do
          a1 = person.additional_emails.create!(email: 'Housi@example.com', translated_label: 'Arbeit', public: 0)
          a2 = person.additional_emails.create!(email: 'Hans@example.com', translated_label: 'Privat', public: 1)
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   additional_emails_attributes: {
                                     a1.id.to_s => { id: a1.id,
                                                     email: 'Housi1@example.com',
                                                     translated_label: 'Arbeit',
                                                     public: 1 },
                                     a2.id.to_s => { id: a2.id, _destroy: true },
                                     '998' => { email: ' ',
                                                translated_label: 'Vater',
                                                public: 1 },
                                     '999' => { email: 'John@example.com',
                                                translated_label: 'Mutter',
                                                public: 0 }, } }
            expect(assigns(:person)).to be_valid
          end.not_to change { AdditionalEmail.count }

          emails = person.reload.additional_emails.order(:label)
          expect(emails.size).to eq(2)
          a = emails.first
          expect(a.label).to eq 'Arbeit'
          expect(a.email).to eq 'Housi1@example.com'
          expect(a.public).to be_truthy
          tw = emails.second
          expect(tw.label).to eq 'Mutter'
          expect(tw.email).to eq 'John@example.com'
          expect(tw.public).to be_falsey
        end

        it 'create, update and destroys people relations' do
          p1 = Fabricate(:person)
          p2 = Fabricate(:person)
          p3 = Fabricate(:person)
          r1 = person.relations_to_tails.create!(tail_id: people(:top_leader).id, kind: 'child')
          r2 = person.relations_to_tails.create!(tail_id: p1.id, kind: 'parent')
          expect do
            put :update, group_id: group.id,
                         id: person.id,
                         person: { town: 'testtown',
                                   relations_to_tails_attributes: {
                                     r1.id.to_s => { id: r1.id,
                                                     tail_id: p2.id,
                                                     kind: 'parent' },
                                     r2.id.to_s => { id: r2.id, _destroy: true },
                                     '998' => { tail_id: ' ',
                                                kind: 'child' },
                                     '999' => { tail_id: p3.id,
                                                kind: 'child' }, } }
            expect(assigns(:person)).to be_valid
          end.not_to change { PeopleRelation.count }

          relations = person.reload.relations_to_tails.order(:tail_id)
          expect(relations.size).to eq(2)
          a = relations.first
          expect(a.tail_id).to eq p2.id
          expect(a.kind).to eq 'parent'
          expect(a.opposite.kind).to eq 'child'
          b = relations.second
          expect(b.tail_id).to eq p3.id
          expect(b.kind).to eq 'child'
          expect(b.opposite.tail_id).to eq person.id
        end
      end
    end

    describe 'GET #show' do
      let(:gl) { qualification_kinds(:gl) }
      let(:sl) { qualification_kinds(:sl) }

      it 'generates pdf labels' do
        get :show, group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id, format: :pdf

        expect(@response.content_type).to eq('application/pdf')
        expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
      end

      it 'exports csv file' do
        get :show, group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id, format: :csv

        expect(@response.content_type).to eq('text/csv')
        expect(@response.body).to match(/^Vorname;Nachname/)
        expect(@response.body).to match(/^Top;Leader/)
      end

      context 'tags' do
        before do
          top_leader.tags.create!(name: 'fruit:banana')
          top_leader.tags.create!(name: 'pizza')
        end

        it 'preloads and assigns grouped tags' do
          get :show, group_id: group.id, id: people(:top_leader).id
          expect(assigns(:tags).map(&:first)).to eq([:fruit, :other])
          expect(assigns(:tags).second.second.map(&:name)).to eq(%w(pizza))
        end
      end

      context 'qualifications' do
        before do
          @ql_gl = Fabricate(:qualification, person: top_leader, qualification_kind: gl, start_at: Time.zone.now)
          @ql_sl = Fabricate(:qualification, person: top_leader, qualification_kind: sl, start_at: Time.zone.now)
        end

        it 'preloads data for asides, ordered by finish_at' do
          get :show, group_id: group.id, id: people(:top_leader).id
          expect(assigns(:person).latest_qualifications_uniq_by_kind).to eq [@ql_sl, @ql_gl]
        end
      end

      context 'add requests' do
        let(:person) { people(:top_leader) }

        it 'loads requests' do
          r1 = Person::AddRequest::Group.create!(
            person: person,
            requester: Fabricate(:person),
            body: groups(:bottom_layer_one),
            role_type: Group::BottomLayer::Member.sti_name)
          get :show, group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_layer_one).id
          expect(assigns(:add_requests)).to eq([r1])
          expect(flash[:notice]).to be_blank
        end

        it 'shows flash status accepted' do
          get :show, group_id: group.id, id: person.id, body_type: 'Group', body_id: group.id
          expect(flash[:notice]).to match(/freigegeben/)
        end

        it 'shows flash status rejected' do
          get :show, group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_group_one_one).id
          expect(flash[:alert]).to match(/abgelehnt/)
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
        expect(flash[:notice]).to eq 'Login Informationen wurden verschickt.'
      end
    end

    describe 'PUT #primary_group' do
      it 'sets primary group' do
        put :primary_group, group_id: group, id: top_leader.id, primary_group_id: group.id, format: :js

        expect(top_leader.reload.primary_group_id).to eq(group.id)
        is_expected.to render_template('primary_group')
      end
    end

  end

  context 'json' do
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
        expect(person['links']['phone_numbers'].size).to eq(2)
        expect(person['links']['roles'].size).to eq(1)
      end

      it 'GET show contains all roles and all data' do
        get :show, group_id: group.id, id: top_leader.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        expect(person['links']['phone_numbers'].size).to eq(2)
        expect(person['links']['roles'].size).to eq(2)
      end
    end

    context 'with contact data' do

      let(:user) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
      before { sign_in(user) }

      it 'GET index contains only current roles and public data' do
        get :index, group_id: group.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        expect(person['links']['phone_numbers'].size).to eq(1)
        expect(person['links']['phone_numbers'].first).to eq(@public_number.id.to_s)
        expect(person['links']['roles'].size).to eq(1)
      end

      it 'GET show contains only current roles and public data' do
        get :show, group_id: group.id, id: top_leader.id, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        expect(person['links']['phone_numbers'].size).to eq(1)
        expect(person['links']['phone_numbers'].first).to eq(@public_number.id.to_s)
        expect(person['links']['roles'].size).to eq(1)
      end
    end
  end

  context 'as reader' do

    before { sign_in(user) }

    let(:user) { Fabricate(Group::TopGroup::LocalSecretary.name, group: groups(:top_group)).person }

    context 'add requests' do
      let(:person) { people(:top_leader) }

      it 'does not load requests' do
        r1 = Person::AddRequest::Group.create!(
          person: person,
          requester: Fabricate(:person),
          body: groups(:bottom_layer_one),
          role_type: Group::BottomLayer::Member.sti_name)
        get :show, group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_layer_one).id
        expect(assigns(:add_requests)).to be_nil
        expect(flash[:notice]).to be_blank
      end
    end

  end

  context 'as api user' do

    describe 'GET #show' do
      it 'redirects when token is nil' do
        get :show, group_id: group.id, id: top_leader.id, user_token: '', user_email: top_leader.email
        is_expected.to redirect_to new_person_session_path
      end

      it 'redirects when token is invalid' do
        get :show, group_id: group.id, id: top_leader.id, user_token: 'yadayada', user_email: top_leader.email
        is_expected.to redirect_to new_person_session_path
      end

      it 'shows page when token is valid' do
        top_leader.generate_authentication_token!
        get :show, group_id: group.id, id: top_leader.id, user_token: top_leader.authentication_token, user_email: top_leader.email
        is_expected.to render_template('show')
      end

      it 'shows page when headers are valid' do
        top_leader.generate_authentication_token!
        @request.headers['X-User-Email'] = top_leader.email
        @request.headers['X-User-Token'] = top_leader.authentication_token
        get :show, group_id: group.id, id: top_leader.id
        is_expected.to render_template('show')
      end
    end

  end
end
