require 'spec_helper'

describe MailingListsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:group) { groups(:top_layer) }

  describe 'GET #index' do
    it 'includes mailing list when person can update group' do
      sign_in(top_leader)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(1).item
    end

    it 'shows mailing list when person cannot update group but mailing list is subscribable' do
      sign_in(bottom_member)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(1).item
    end

    it 'hides mailing list when person cannot update group' do
      sign_in(bottom_member)
      mailing_lists(:leaders).update(subscribable: false)
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to be_empty
    end

    it 'sorts by name' do
      sign_in(top_leader)
      bar = group.mailing_lists.create(name: 'Bar')
      get :index, params: { group_id: group.id }
      expect(assigns(:mailing_lists)).to have(2).item
      expect(assigns(:mailing_lists).first).to eq bar
    end
  end

  describe 'GET #show JSON' do

    let(:mailing_list) { group.mailing_lists.create(name: 'Bar',
                                                    description: 'Description',
                                                    publisher: 'Publisher',
                                                    mail_name: 'my-mailing-list',
                                                    additional_sender: 'someone@somewhere.com',
                                                    subscribable: true,
                                                    subscribers_may_post: true,
                                                    anyone_may_post: true,
                                                    preferred_labels: ['some', 'labels'],
                                                    delivery_report: true,
                                                    main_email: true) }

    let(:expected_mailing_list) {({
      id: mailing_list.id.to_s,
      type: 'mailing_lists',
      name: 'Bar',
      description: 'Description',
      publisher: 'Publisher',
      mail_name: 'my-mailing-list',
      additional_sender: 'someone@somewhere.com',
      subscribable: true,
      subscribers_may_post: true,
      anyone_may_post: true,
      preferred_labels: ['labels', 'some'],
      delivery_report: true,
      main_email: true,
      links: { group: group.id.to_s }
    })}
    let(:expected_linked) {({
      groups: [{
        id: group.id.to_s,
        name: 'Top',
        group_type: 'Top Layer'
      }]
    })}

    it 'shows mailing list when person can update group' do
      sign_in(top_leader)
      get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
      json = JSON.parse(@response.body)
      expect(json).to eq({ mailing_lists: [expected_mailing_list], linked: expected_linked }.with_indifferent_access)
    end

    it 'shows subscribers' do
      subscription = Fabricate(:subscription, mailing_list: mailing_list, excluded: false)
      person = subscription.subscriber
      person.update(primary_group: group)
      sign_in(top_leader)
      get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
      json = JSON.parse(@response.body)
      expect(json).to eq({
        mailing_lists: [expected_mailing_list.deep_merge({
          links: {
            subscribers: [person.id.to_s]
          },
        })],
        linked: expected_linked.deep_merge({
          people: [{
            id: person.id.to_s,
            address: person.address,
            company: person.company,
            company_name: person.company_name,
            country: person.country,
            email: person.email,
            first_name: person.first_name,
            last_name: person.last_name,
            nickname: person.nickname,
            primary_group_id: group.id,
            primary_group_name: group.name,
            town: person.town,
            zip_code: person.zip_code,
            list_emails: [person.email],
          }]
        })
      }.with_indifferent_access)
    end

    it 'shows subscribers even without primary group' do
      subscription = Fabricate(:subscription, mailing_list: mailing_list, excluded: false)
      person = subscription.subscriber
      person.update(primary_group: nil)
      sign_in(top_leader)
      get :show, params: { group_id: group.id, id: mailing_list.id }, format: :json
      json = JSON.parse(@response.body)
      expect(json).to eq({
        mailing_lists: [expected_mailing_list.deep_merge({
          links: {
            subscribers: [person.id.to_s]
          },
        })],
        linked: expected_linked.deep_merge({
          people: [{
            id: person.id.to_s,
            address: person.address,
            company: person.company,
            company_name: person.company_name,
            country: person.country,
            email: person.email,
            first_name: person.first_name,
            last_name: person.last_name,
            nickname: person.nickname,
            primary_group_id: nil,
            primary_group_name: nil,
            town: person.town,
            zip_code: person.zip_code,
            list_emails: [person.email],
          }]
        })
      }.with_indifferent_access)
    end
  end
end
