# encoding: UTF-8
require 'spec_helper'

describe Devise::PasswordsController do
  let(:bottom_group) { groups(:bottom_group_one_one) }
  
  before do 
    request.env['devise.mapping'] = Devise.mappings[:person] 
    ActionMailer::Base.deliveries = []
  end

  describe "#create" do
    it "#create with invalid email invalid password" do
      post :create, person: {email: 'asdf'}
      last_email.should_not be_present
      controller.resource.errors[:email].should eq ['nicht gefunden']
    end

    context "with login permission" do
      let(:person) { Fabricate("Group::BottomGroup::Leader", group: bottom_group).person.reload }

      it "#create shows invalid password" do
        post :create, person: { email: person.email }
        flash[:notice].should eq "Du erhältst in wenigen Minuten eine E-Mail mit der Anleitung, wie Du Dein Passwort zurücksetzen kannst."
        last_email.should be_present
      end
    end

    context "without login permission" do
      let(:person) { Fabricate("Group::BottomGroup::Member", group: bottom_group).person.reload }

      it "#create shows invalid password" do
        post :create, person: { email: person.email }
        last_email.should_not be_present
        flash[:alert].should eq  "Du kannst kein Passwort nicht zurücksetzen lassen."
      end
    end

    def last_email
      ActionMailer::Base.deliveries.last
    end
  end

end
