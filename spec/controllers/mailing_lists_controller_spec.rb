require 'spec_helper'

describe MailingListsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  describe 'GET #index' do
    let(:group) { groups(:top_layer) }

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
  end
end
