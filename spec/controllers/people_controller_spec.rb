# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
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
        Fabricate(:phone_number, contactable: @tg_member, number: '+41 44 123 45 67', label: 'Privat', public: true)
        Fabricate(:phone_number, contactable: @tg_member, number: '+41 77 456 78 90', label: 'Mobile', public: false)
        Fabricate(:phone_number, contactable: @tg_member, number: '+41 800 789 012', label: 'Office', public: true)
        Fabricate(:social_account, contactable: @tg_member, name: 'facefoo', label: 'Facebook', public: true)
        Fabricate(:social_account, contactable: @tg_member, name: 'skypefoo', label: 'Skype', public: false)
        Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one), person: @tg_member)
        @tg_extern = Fabricate(Role::External.name.to_sym, group: groups(:top_group)).person

        @bl_leader = Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person
        @bl_extern = Fabricate(Role::External.name.to_sym, group: groups(:bottom_layer_one)).person

        @bg_leader = Fabricate(Group::BottomGroup::Leader.name.to_sym, group: groups(:bottom_group_one_one)).person
        @bg_member = Fabricate(Group::BottomGroup::Member.name.to_sym, group: groups(:bottom_group_one_one)).person
        @tg_member.update(first_name: 'Al', last_name: 'Zoe', nickname: 'al', town: 'Eye', zip_code: '8000')
      end

      context 'sorting' do
        before do
          top_leader.update(first_name: 'Joe', last_name: 'Smith', nickname: 'js', town: 'Stoke', address: 'Howard Street', zip_code: '9000')
          @tg_extern.update(first_name: '', last_name: 'Bundy', nickname: '', town: '', address: '', zip_code: '')
        end

        let(:role_type_ids) { [Role::External.id, Group::TopGroup::Leader.id, Group::TopGroup::Member.id].join('-') }


        context 'default sort' do
          it "sorts by name" do
            get :index, params: { group_id: group, range: 'layer', filters: { role: { role_type_ids: role_type_ids } } }
            expect(assigns(:people).collect(&:id)).to eq([@tg_extern, top_leader,  @tg_member].collect(&:id))
          end

          it "people.default_sort setting can override it to sort by role" do
            allow(Settings.people).to receive_messages(default_sort: 'role')
            get :index, params: { group_id: group, range: 'layer', filters: { role: { role_type_ids: role_type_ids }} }
            expect(assigns(:people).collect(&:id)).to eq([top_leader,  @tg_member, @tg_extern].collect(&:id))
          end
        end

        it "sorts based on last_name" do
          get :index, params: { group_id: group, range: 'layer', filters: { role: { role_type_ids: role_type_ids } }, sort: :last_name, sort_dir: :asc }
          expect(assigns(:people).collect(&:id)).to eq([@tg_extern, top_leader,  @tg_member].collect(&:id))
        end

        it "sorts based on roles" do
          get :index, params: { group_id: group, range: 'layer', filters: { role: { role_type_ids: role_type_ids } }, sort: :roles, sort_dir: :asc }
          expect(assigns(:people)).to eq([top_leader,  @tg_member, @tg_extern])
        end

        %w(first_name nickname zip_code town).each do |attr|
          it "sorts based on #{attr}" do
            get :index, params: { group_id: group, range: 'layer', filters: { role: { role_type_ids: role_type_ids } }, sort: attr, sort_dir: :asc }
            expect(assigns(:people)).to eq([@tg_member, top_leader,  @tg_extern])
          end
        end
      end

      context 'group' do
        it 'loads all members of a group' do
          get :index, params: { group_id: group }

          expect(assigns(:people).collect(&:id)).to match_array([top_leader, @tg_member].collect(&:id))
          expect(assigns(:person_add_requests)).to eq([])
        end

        it 'loads externs of a group when type given' do
          get :index, params: { group_id: group, filters: { role: { role_type_ids: [Role::External.id].join('-') } } }

          expect(assigns(:people).collect(&:id)).to match_array([@tg_extern].collect(&:id))
        end

        it 'loads selected roles of a group when types given' do
          get :index, params: { group_id: group, filters: { role: { role_type_ids: [Role::External.id, Group::TopGroup::Member.id].join('-') } } }

          expect(assigns(:people).collect(&:id)).to match_array([@tg_member, @tg_extern].collect(&:id))
        end

        it 'loads pending person add requests' do
          r1 = Person::AddRequest::Group.create!(
                  person: Fabricate(:person),
                  requester: Fabricate(:person),
                  body: group,
                  role_type: group.class.role_types.first.sti_name)

          get :index, params: { group_id: group.id }

          expect(assigns(:person_add_requests)).to eq([r1])
        end

        context '.pdf' do
          it 'generates pdf labels' do
            get :index, params: { group_id: group, label_format_id: label_formats(:standard).id }, format: :pdf

            expect(@response.media_type).to eq('application/pdf')
            expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
          end
        end

        context 'background job' do
          it 'exports csv' do
            expect do
              get :index, params: { group_id: group }, format: :csv
              expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
              expect(response).to redirect_to(returning: true)
            end.to change(Delayed::Job, :count).by(1)
          end

          it 'exports xlsx' do
            expect do
              get :index, params: { group_id: group }, format: :xlsx
              expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
              expect(response).to redirect_to(returning: true)
            end.to change(Delayed::Job, :count).by(1)
          end

          it 'sets cookie on export' do
            get :index, params: { group_id: group }, format: :csv

            cookie = JSON.parse(cookies[Cookies::AsyncDownload::NAME])

            expect(cookie[0]['name']).to match(/^(people_export)+\S*(#{top_leader.id})+$/)
            expect(cookie[0]['type']).to match(/^csv$/)
          end
        end

        context '.vcf' do
          it 'exports vcf files' do
            e1 = Fabricate(:additional_email, contactable: @tg_member, public: true)
            e2 = Fabricate(:additional_email, contactable: @tg_member, public: false)
            @tg_member.update(birthday: '09.10.1978')

            get :index, params: { group_id: group }, format: :vcf

            expect(@response.media_type).to eq('text/vcard')
            cards = @response.body.split("END:VCARD\n")
            expect(cards.length).to equal(2);

            if cards[1].include?("N:Member;Bottom")
              cards.reverse!
            end

            expect(cards[0][0..23]).to eq("BEGIN:VCARD\nVERSION:3.0\n")
            expect(cards[0]).to match(/^N:Leader;Top;;;/)
            expect(cards[0]).to match(/^FN:Top Leader/)
            expect(cards[0]).to match(/^ADR:;;;Supertown;;;/)
            expect(cards[0]).to match(/^EMAIL;TYPE=pref:top_leader@example.com/)
            expect(cards[0]).not_to match(/^TEL.*/)
            expect(cards[0]).not_to match(/^NICKNAME.*/)
            expect(cards[0]).not_to match(/^BDAY.*/)

            expect(cards[1][0..23]).to eq("BEGIN:VCARD\nVERSION:3.0\n")
            expect(cards[1]).to match(/^N:Zoe;Al;;;/)
            expect(cards[1]).to match(/^FN:Al Zoe/)
            expect(cards[1]).to match(/^NICKNAME:al/)
            expect(cards[1]).to match(/^ADR:;;;Eye;;8000;/)
            expect(cards[1]).to match(/^EMAIL;TYPE=pref:#{@tg_member.email}/)
            expect(cards[1]).to match(/^EMAIL;TYPE=privat:#{e1.email}/)
            expect(cards[1]).not_to match(/^EMAIL.*:#{e2.email}/)
            expect(cards[1]).to match(/^TEL;TYPE=privat:\+41 44 123 45 67/)
            expect(cards[1]).to match(/^TEL;TYPE=office:\+41 800 789 012/)
            expect(cards[1]).not_to match(/^TEL.*:\+41 77 456 78 90/)
            expect(cards[1]).to match(/^BDAY:19781009/)
          end
        end

        context '.email' do
          it 'renders email addresses' do
            get :index, params: { group_id: group }, format: :email
            expect(@response.media_type).to eq('text/plain')
            expect(@response.body).to eq("top_leader@example.com,#{@tg_member.email}")
          end

          it 'renders email addresses with additional ones' do
            e1 = Fabricate(:additional_email, contactable: @tg_member, mailings: true)
            Fabricate(:additional_email, contactable: @tg_member, mailings: false)
            get :index, params: { group_id: group }, format: :email
            expect(@response.body).to eq("top_leader@example.com,#{@tg_member.email},#{e1.email}")
          end
        end

        context '.json' do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, params: { group_id: group }, format: :json
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

          it 'loads people in layer when no types given' do
            get :index, params: { group_id: group, range: 'layer' }

            expect(assigns(:people).collect(&:id)).to match_array(
              [ people(:bottom_member),
                @bl_leader,
                @bl_extern,
                @bg_leader,
                @bg_member,
                @tg_member # also has Group::BottomGroup::Leader role
              ].collect(&:id)
            )
          end

          it 'loads selected roles of a group when types given' do
            get :index, params: {
                          group_id: group,
                          filters: { role: { role_type_ids: [Group::BottomGroup::Member.id, Role::External.id].join('-') } },
                          range: 'layer'
                        }

            expect(assigns(:people).collect(&:id)).to match_array([@bg_member, @bl_extern].collect(&:id))
          end

          it 'does not load pending person add requests' do
            r1 = Person::AddRequest::Group.create!(
              person: Fabricate(:person),
              requester: Fabricate(:person),
              body: group,
              role_type: group.class.role_types.first.sti_name)

            get :index, params: { group_id: group.id, range: 'layer' }

            expect(assigns(:person_add_requests)).to be_nil
          end

          context 'json' do
            render_views

            it 'renders json with only the one role in this group' do
              get :index, params: {
                            group_id: group,
                            range: 'layer',
                            filters: { role: { role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-') } }
                          },
                          format: :json
              json = JSON.parse(@response.body)
              person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
              expect(person['links']['roles'].size).to eq(2)
            end
          end
        end
      end

      context 'deep' do
        let(:group) { groups(:top_layer) }

        it 'loads people in subtree when no types are given' do
          get :index, params: { group_id: group, range: 'deep' }

          expect(assigns(:people).collect(&:id)).to match_array([people(:top_leader),
                                                                 people(:bottom_member),
                                                                 @tg_member,
                                                                 @tg_extern,
                                                                 @bl_leader,
                                                                 @bg_leader].collect(&:id))
        end

        it 'loads selected roles of a group when types given' do
          get :index, params: {
                        group_id: group,
                        filters: { role: { role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-') } },
                        range: 'deep'
                      }

          expect(assigns(:people).collect(&:id)).to match_array([@bg_leader, @tg_member, @tg_extern].collect(&:id))
        end

        context 'json' do
          render_views

          it 'renders json with only the one role in this group' do
            get :index, params: {
                          group_id: group,
                          range: 'deep',
                          filters: { role: { role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-') } }
                        },
                        format: :json
            json = JSON.parse(@response.body)
            person = json['people'].find { |p| p['id'] == @tg_member.id.to_s }
            expect(person['links']['roles'].size).to eq(2)
          end
        end
      end

      context 'filter_id' do
        let(:group) { groups(:top_layer) }

        it 'loads selected roles of a group' do
          filter = PeopleFilter.create!(
            name: 'My Filter',
            range: 'deep',
            filter_chain: {
              role: { role_type_ids: [Group::BottomGroup::Leader.id, Role::External.id].join('-') }
            }
          )

          get :index, params: { group_id: group, filter_id: filter.id }

          expect(assigns(:people).collect(&:id)).to match_array([@bg_leader, @tg_member, @tg_extern].collect(&:id))
        end
      end
    end

    context 'PUT update' do
      let(:person) { people(:bottom_member) }
      let(:group) { person.groups.first }

      it 'as admin updates email with password' do
        put :update, params: { group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' } }
        expect(assigns(:person).email).to eq('foo@example.com')
      end

      context 'as bottom leader' do
        before { sign_in(Fabricate(Group::BottomLayer::Leader.sti_name, group: group).person) }

        it 'updates email for person in one group' do
          person.update_column(:encrypted_password, nil)
          put :update, params: { group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' } }
          expect(assigns(:person).email).to eq('foo@example.com')
        end

        it 'does not update email for person in multiple groups' do
          Fabricate(Group::BottomLayer::Member.name.to_sym, person: person, group: groups(:bottom_layer_two))
          put :update, params: { group_id: group.id, id: person.id, person: { last_name: 'Foo', email: 'foo@example.com' } }
          expect(assigns(:person).email).to eq('bottom_member@example.com')
        end

        it 'does not update password for other person' do
          encrypted = person.encrypted_password
          put :update, params: {
                         group_id: group.id,
                         id: person.id,
                         person: { password: 'yadayada', password_confirmation: 'yadayada' }
                       }
          expect(person.reload.encrypted_password).to eq encrypted
        end

        it 'create new phone numbers' do
          expect do
            put :update, params: {
                           group_id: group.id,
                           id: person.id,
                           person: { town: 'testtown',
                                     phone_numbers_attributes: {
                                       '111' =>
                                         { number: '031 111 1111', translated_label: 'Privat', public: 1 },
                                       '222' =>
                                         { number: '', translated_label: 'Arbeit', public: 1 }  } }
                         }
            expect(assigns(:person)).to be_valid
          end.to change { PhoneNumber.count }.by(1)
          expect(person.reload.phone_numbers.size).to eq(1)
          number = person.phone_numbers.first
          expect(number.number).to eq '+41 31 111 11 11'
          expect(number.label).to eq 'Privat'
          expect(number.public).to be_truthy
        end

        it 'updates existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, params: {
                           group_id: group.id,
                           id: person.id,
                           person: { town: 'testtown',
                                     phone_numbers_attributes: { n.id.to_s =>
                                       { number: '031 111 2222', translated_label: 'Privat', public: 0, id: n.id } } }
                         }
          end.not_to change { PhoneNumber.count }
          number = person.reload.phone_numbers.first
          expect(number.number).to eq '+41 31 111 22 22'
          expect(number.public).to be_falsey
        end

        it 'updates existing phone numbers in other language' do
          @cached_locales = I18n.available_locales
          @cached_languages = Settings.application.languages
          Settings.application.languages = { de: 'Deutsch', fr: 'Français' }
          I18n.available_locales = Settings.application.languages.keys

          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Vater', public: 1)
          expect do
            put :update, params: {
                           group_id: group.id,
                           id: person.id,
                           locale: :fr,
                           person: { town: 'testtown',
                                     phone_numbers_attributes: { n.id.to_s =>
                                       { number: '031 111 2222', translated_label: 'mère', public: 0, id: n.id } } }
                         }
          end.not_to change { PhoneNumber.count }

          I18n.available_locales = @cached_locales
          Settings.application.languages = @cached_languages
          I18n.locale = I18n.default_locale

          number = person.reload.phone_numbers.first
          expect(number.number).to eq '+41 31 111 22 22'
          expect(number.label).to eq 'Mutter'
          expect(number.public).to be_falsey
        end

        it 'destroys existing phone numbers' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, params: {
                           group_id: group.id,
                           id: person.id,
                           person: { town: 'testtown',
                                     phone_numbers_attributes: { n.id.to_s =>
                                       { number: '031 111 1111', translated_label: 'Privat', public: 0, id: n.id, _destroy: true } } }
                         }
          end.to change { PhoneNumber.count }.by(-1)
          expect(person.reload.phone_numbers).to be_blank
        end

        it 'destroys existing phone numbers when number is empty' do
          n = person.phone_numbers.create!(number: '031 111 1111', label: 'Privat', public: 1)
          expect do
            put :update, params: {
                           group_id: group.id,
                           id: person.id,
                           person: { town: 'testtown',
                                     phone_numbers_attributes: { n.id.to_s =>
                                       { number: '   ', translated_label: 'Privat', public: 0, id: n.id } } }
                         }
          end.to change { PhoneNumber.count }.by(-1)
          expect(person.reload.phone_numbers).to be_blank
        end

        it 'create, update and destroys social accounts' do
          a1 = person.social_accounts.create!(name: 'Housi', label: 'Facebook', public: 0)
          a2 = person.social_accounts.create!(name: 'Hans', label: 'Skype', public: 1)
          expect do
            put :update, params: {
                           group_id: group.id,
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
                         }
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
            put :update, params: {
                           group_id: group.id,
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
                         }
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
            put :update, params: {
                           group_id: group.id,
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
                         }
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
        get :show, params: { group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id }, format: :pdf

        expect(@response.media_type).to eq('application/pdf')
        expect(people(:top_leader).reload.last_label_format).to eq(label_formats(:standard))
      end

      it 'exports csv file' do
        get :show, params: { group_id: group, id: top_leader.id, label_format_id: label_formats(:standard).id }, format: :csv

        expect(@response.media_type).to eq('text/csv')
        expect(@response.body).to match(/^Vorname;Nachname/)
        expect(@response.body).to match(/^Top;Leader/)
      end

      context 'tags' do
        before do
          top_leader.tags.create!(name: 'fruit:banana')
          top_leader.tags.create!(name: 'pizza')
        end

        it 'preloads and assigns grouped tags' do
          get :show, params: { group_id: group.id, id: people(:top_leader).id }
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
          get :show, params: { group_id: group.id, id: people(:top_leader).id }
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
          get :show, params: { group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_layer_one).id }
          expect(assigns(:add_requests)).to eq([r1])
          expect(flash[:notice]).to be_blank
        end

        it 'shows flash status accepted' do
          get :show, params: { group_id: group.id, id: person.id, body_type: 'Group', body_id: group.id }
          expect(flash[:notice]).to match(/freigegeben/)
        end

        it 'shows flash status rejected' do
          get :show, params: { group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_group_one_one).id }
          expect(flash[:alert]).to match(/abgelehnt/)
        end
      end

    end

    describe 'POST #send_password_instructions' do
      let(:person) { people(:bottom_member) }

      before { allow(Truemail).to receive(:valid?).and_call_original }

      it 'does not send instructions for self' do
        expect do
          expect do
            post :send_password_instructions, params: { group_id: group.id, id: top_leader.id }, format: :js
          end.to raise_error(CanCan::AccessDenied)
        end.not_to change { Delayed::Job.count }
      end

      it 'sends password instructions' do
        expect do
          post :send_password_instructions, params: { group_id: groups(:bottom_layer_one).id, id: person.id }, format: :js
        end.to change { Delayed::Job.count }.by(1)
        expect(flash[:notice]).to eq 'Login Informationen wurden verschickt.'
      end

      it 'does not send instructions if e-mail invalid' do
        person.update_attribute(:email, 'dude@domainungueltig42.ch')

        expect do
          post :send_password_instructions, params: { group_id: groups(:bottom_layer_one).id, id: person.id }, format: :js
        end.not_to change { Delayed::Job.count }
        expect(flash[:alert]).to eq 'Die Login-Informationen wurden nicht verschickt da die hinterlegte E-Mail Adresse ungültig ist.'
      end
    end

    describe 'PUT #primary_group' do
      it 'sets primary group' do
        put :primary_group, params: { group_id: group, id: top_leader.id, primary_group_id: group.id }, format: :js

        expect(top_leader.reload.primary_group_id).to eq(group.id)
        is_expected.to render_template('primary_group')
      end

      it 'does not set primary group if person has invalid data' do
        top_leader.update_columns(first_name: nil, last_name: nil) # produce invalid person model
        put :primary_group, params: { group_id: group, id: top_leader.id, primary_group_id: group.id }, format: :js

        expect(top_leader.reload.primary_group_id).to eq(group.id)
        is_expected.to render_template('shared/update_flash')
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
        get :index, params: { group_id: group.id }, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        expect(person['links']['phone_numbers'].size).to eq(2)
        expect(person['links']['roles'].size).to eq(1)
      end

      it 'GET show contains all roles and all data' do
        get :show, params: { group_id: group.id, id: top_leader.id }, format: :json
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
        get :index, params: { group_id: group.id }, format: :json
        json = JSON.parse(response.body)
        person = json['people'].first
        expect(person['links']['phone_numbers'].size).to eq(1)
        expect(person['links']['phone_numbers'].first).to eq(@public_number.id.to_s)
        expect(person['links']['roles'].size).to eq(1)
      end

      it 'GET show contains only current roles and public data' do
        get :show, params: { group_id: group.id, id: top_leader.id }, format: :json
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
        get :show, params: { group_id: group.id, id: person.id, body_type: 'Group', body_id: groups(:bottom_layer_one).id }
        expect(assigns(:add_requests)).to be_nil
        expect(flash[:notice]).to be_blank
      end
    end

  end

  context 'as api user' do

    describe 'GET #show' do
      it 'redirects when token is nil' do
        get :show, params: { group_id: group.id, id: top_leader.id, user_token: '', user_email: top_leader.email }
        is_expected.to redirect_to new_person_session_path
      end

      it 'redirects when token is invalid' do
        get :show, params: { group_id: group.id, id: top_leader.id, user_token: 'yadayada', user_email: top_leader.email }
        is_expected.to redirect_to new_person_session_path
      end

      it 'shows page when token is valid' do
        top_leader.generate_authentication_token!
        get :show, params: { group_id: group.id, id: top_leader.id, user_token: top_leader.authentication_token, user_email: top_leader.email }
        is_expected.to render_template('show')
      end

      it 'shows page when headers are valid' do
        top_leader.generate_authentication_token!
        @request.headers['X-User-Email'] = top_leader.email
        @request.headers['X-User-Token'] = top_leader.authentication_token
        get :show, params: { group_id: group.id, id: top_leader.id }
        is_expected.to render_template('show')
      end
    end

  end

  context 'DELETE #destroy' do

    let(:member) { people(:bottom_member) }
    let(:admin) { people(:top_leader) }

    describe 'as admin user' do
      before { sign_in(admin) }

      it 'can delete person' do
        delete :destroy, params: { group_id: member.primary_group.id, id: member.id }
        expect(response.status).to eq(302)
      end

      it 'deletes person' do
        expect do
          delete :destroy, params: { group_id: member.primary_group.id, id: member.id }
        end.to change(Person, :count).by(-1)
      end
    end

    describe 'as normal user' do
      before { sign_in(member) }

      it 'fails without permissions' do
        expect do
          delete :destroy, params: { group_id: group.id, id: admin.id }
        end.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  context 'households' do
    let(:member) { people(:bottom_member) }
    before { sign_in(top_leader) }

    it 'POST#update creates household' do
      put :update, params: { group_id: group.id, id: top_leader.id, person: { household_people_ids: [member.id] } }

      expect(top_leader.reload.household_key).to be_present
      expect(top_leader.household_people).to eq [member]
    end

    it 'POST#update clears household' do
      top_leader.update(household_key: 1)
      put :update, params: { group_id: group.id, id: top_leader.id, person: { town: top_leader.town } }

      expect(top_leader.reload.household_key).to be_nil
    end

    it 'POST#update rerenders edit formal when not permitted to update addresse' do
      sign_in(member)
      put :update, params: { group_id: member.primary_group_id, id: member.id, person: { household_people_ids: [top_leader.id] } }
      expect(assigns(:person)).to have(4).errors
      expect(response).to render_template('edit')
    end

    it 'POST#update does not accept invalid file type' do
      file = Tempfile.new(['foo', '.exe'])
      picture = Rack::Test::UploadedFile.new(file, 'application/exe')
      put :update, params: { group_id: member.primary_group_id, id: member.id, person: { picture: picture } }
      expect(assigns(:person)).to have(1).error_on(:picture)
    end
  end

  context 'as token user' do
    it 'shows page when token is valid' do
      get :show, params: { group_id: group.id, id: top_leader.id, token: 'PermittedToken' }
      is_expected.to render_template('show')
    end

    it 'does not show page for unpermitted token' do
      expect do
        get :show, params: { group_id: group.id, id: top_leader.id, token: 'RejectedToken' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'indexes page when token is valid' do
      get :index, params: { group_id: group.id, token: 'PermittedToken' }
      is_expected.to render_template('index')
    end

    it 'does not index page for unpermitted token' do
      expect do
        get :index, params: { group_id: group.id, token: 'RejectedToken' }
      end.to raise_error(CanCan::AccessDenied)
    end

    context 'bottom_group' do
      let(:group)  { groups(:bottom_group_one_one_one) }

      before do
        @member = Fabricate(Group::BottomGroup::Member.sti_name, group: group).person
        @leader = Fabricate(Group::BottomGroup::Leader.sti_name, group: group).person
      end

      it 'shows only leader in list' do
        get :index, params: { group_id: group.id, token: 'PermittedToken' }
        expect(assigns(:people)).to eq [@leader]
      end

      it 'shows leader' do
        get :show, params: { group_id: group.id, id: @leader.id, token: 'PermittedToken' }
        expect(response).to be_successful
      end

      it 'raises when trying to view member' do
        expect do
          get :show, params: { group_id: group.id, id: @member.id, token: 'PermittedToken' }
        end.to raise_error CanCan::AccessDenied
      end
    end
  end

  context 'table_displays'do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    before { sign_in(top_leader) }
    after  { TableDisplay.class_variable_set('@@permissions', {}) }

    it 'GET#index lists extra column' do
      top_leader.table_display_for(group).update(selected: %w(gender))

      get :index, params: { group_id: group.id }
      expect(dom).to have_checked_field 'Geschlecht'
      expect(dom.find('table tbody tr')).to have_content 'unbekannt'
    end

    it 'GET#index lists extra column without content if permission check fails' do
      TableDisplay.register_permission(Person, :missing_permission, :gender)
      top_leader.table_display_for(group).update(selected: %w(gender))

      get :index, params: { group_id: group.id }
      expect(dom).to have_checked_field 'Geschlecht'
      expect(dom.find('table tbody tr')).not_to have_content 'unbekannt'
    end

    it 'GET#index sorts by extra column' do
      top_leader.table_display_for(group).update(selected: %w(gender))
      Fabricate(Group::TopGroup::Member.name.to_sym, group: groups(:top_group)).person.update(gender: 'm')
      get :index, params: { group_id: group.id, sort: :gender, sort_dir: :desc }
      expect(assigns(:people).first).to eq top_leader
    end

    it 'GET#index exports to csv using TableDisplay' do
      get :index, params: { group_id: group, selection: true }, format: :csv
      expect(flash[:notice]).to match(/Export wird im Hintergrund gestartet und nach Fertigstellung heruntergeladen./)
      expect(Delayed::Job.last.payload_object.send(:exporter)).to eq Export::Tabular::People::TableDisplays
    end
  end
end
