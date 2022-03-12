require 'spec_helper'

describe MailingListsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:group) { groups(:top_layer) }

  describe 'GET #index' do
    it 'includes mailing list when person can update group' do
      sign_in(top_leader)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(2).items
    end

    it 'shows mailing list when person cannot update group but mailing list is subscribable' do
      sign_in(bottom_member)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(2).items
    end

    it 'hides mailing list when person cannot update group' do
      sign_in(bottom_member)
      mailing_lists(:leaders).update(subscribable: false)
      mailing_lists(:members).update(subscribable: false)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to be_empty
    end

    it 'sorts by name' do
      sign_in(top_leader)
      bar = group.mailing_lists.create(name: 'Bar')
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(3).items
      expect(assigns(:mailing_lists).first).to eq bar
    end

    it 'renders json' do
      sign_in(top_leader)
      get :index, params: { group_id: group.id }, format: :json
      json = JSON.parse(@response.body).deep_symbolize_keys
      expect(json[:current_page]).to eq 1
      expect(json[:total_pages]).to eq 1
      expect(json[:next_page_link]).to be_nil
      expect(json[:prev_page_link]).to be_nil
      expect(json[:mailing_lists]).to have(2).items
      expect(json[:mailing_lists].collect { |list| list[:id] }).to eq [mailing_lists(:leaders).id.to_s, mailing_lists(:members).id.to_s]
    end
  end

  describe 'GET #show JSON' do
    let(:mailing_list) { mailing_lists(:leaders) }
    let(:expected_linked) {({
      groups: [{
        id: group.id.to_s,
        name: group.name,
        group_type: group.class.label
      }]
    })}
    let(:expected_mailing_list) {
      [
        mailing_list.slice(
          'name', 'description', 'publisher', 'mail_name',
          'additional_sender', 'subscribable', 'subscribers_may_post', 'anyone_may_post',
          'preferred_labels', 'delivery_report', 'main_email'
        ),
        { id: mailing_list.id.to_s, type: 'mailing_lists', links: { group: group.id.to_s } }
      ].inject(&:merge).deep_symbolize_keys
    }
    before { sign_in(top_leader) }

    it 'shows mailing list when person can update group' do
      get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
      json = JSON.parse(@response.body).deep_symbolize_keys
      expect(json[:mailing_lists]).to have(1).item
      expect(json).to eq({ mailing_lists: [expected_mailing_list], linked: expected_linked })
    end

    context 'subscribers' do
      let(:subscriber) { Fabricate(:subscription, mailing_list: mailing_list, excluded: false).subscriber }
      let(:expected_subscriber) {([subscriber.slice(
        'address', 'company', 'company_name', 'country', 'email',
        'first_name', 'last_name', 'nickname', 'primary_group_id',
        'town', 'zip_code'
      ), { id: subscriber.id.to_s }, list_emails: [subscriber.email] ].inject(&:merge).deep_symbolize_keys
      )}

      it 'shows subscribers' do
        subscriber.update(primary_group: group)
        get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
        json = JSON.parse(@response.body).deep_symbolize_keys
        expect(json).to eq({
          mailing_lists: [expected_mailing_list.deep_merge({
            links: {
              subscribers: [subscriber.id.to_s]
            },
          })],
          linked: expected_linked.deep_merge({
            people: [expected_subscriber.merge({ primary_group_name: group.name })]
          })
        })
      end

      it 'shows subscribers even without primary group' do
        subscriber.update(primary_group: nil)
        get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
        json = JSON.parse(@response.body).deep_symbolize_keys
        expect(json).to eq({
          mailing_lists: [expected_mailing_list.deep_merge({
            links: {
              subscribers: [subscriber.id.to_s]
            },
          })],
          linked: expected_linked.deep_merge({
            people: [expected_subscriber.merge({ primary_group_name: nil })]
          })
        })
      end
    end
  end
end
