require 'spec_helper'

describe MailingList::MailLogsController do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }
  let(:mailing_list) { mailing_lists(:leaders) }

  before do
    10.times do
      MailLog.create!(mailing_list: mailing_list,
                      mail_subject: 'Subject 42',
                      mail_from: Faker::Internet.email,
                      mail_hash: Digest::MD5.new.hexdigest(Faker::Lorem.characters(200)))
    end
  end

  describe 'GET #index' do
    let(:group) { groups(:top_layer) }

    it 'includes mailing list\'s mail log when person can update mailing list' do
      sign_in(top_leader)
      get :index, params: { group_id: group.id, mailing_list_id: mailing_list.id }
      expect(assigns(:mail_logs)).to have(10).item
    end

    it 'denies access to mail log when person cannot update mailing list' do
      sign_in(bottom_member)
      expect do
        get :index, params: { group_id: group.id, mailing_list_id: mailing_list.id }
      end.to raise_error(CanCan::AccessDenied)
    end

  end
end
