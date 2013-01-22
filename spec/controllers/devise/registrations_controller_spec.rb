# encoding: UTF-8
require 'spec_helper'

describe Devise::RegistrationsController do
  before { request.env['devise.mapping'] = Devise.mappings[:person] }
  render_views

  let(:person) { people(:top_leader) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(person) }

  subject { dom }
  
  describe "GET #edit" do

    context "user with password" do
      before { get :edit }
      it { should have_content 'Passwort ändern' }
      it { should have_content 'Altes Passwort' }
    end

    context "user without password" do
      before { person.update_column(:encrypted_password, nil) }
      before { sign_in(person) }
      before { get :edit }

      it { should have_content 'Passwort setzen' }
      it { should_not have_content 'Altes Passwort' }
    end
  end

  describe "put #update" do
    let(:data) { { password: 'foofoo', password_confirmation: 'foofoo' } }

    context "with old password" do
      before { put :update, person: data.merge(current_password: 'foobar') }

      it { should redirect_to(root_path) }
      it { flash[:notice].should eq 'Deine Daten wurden aktualisiert.' }
    end
    
    context "with wrong old password" do
      before { put :update, person: data.merge(current_password: 'barfoo') }

      it { should render_template('edit') }
      it { should have_content 'Altes Passwort ist nicht gültig' }
    end
    
    context "without old password" do
      before { put :update, person: data }

      it { should render_template('edit') }
      it { should have_content 'Altes Passwort muss ausgefüllt werden' }
    end

    context "user without password" do
      before { person.update_column(:encrypted_password, nil) }
      before { sign_in(person) }
      before { put :update, person: data }

      it { should redirect_to(root_path) }
      it { flash[:notice].should eq 'Deine Daten wurden aktualisiert.' }
    end

    context "with wrong confirmation" do
      before { put :update, person: { current_password: 'foobar', passsword: 'foofoo', password_confirmation: 'barfoo' } }

      it { should render_template('edit') }
      it { should have_content 'Passwort stimmt nicht mit der Bestätigung überein' }
    end
    
    
    context "with empty password" do
      it "does not change password" do
        old = person.encrypted_password
        put :update, person: { current_password: 'foobar', passsword: '', password_confirmation: '' }
        
        should redirect_to(root_path)
        person.reload.encrypted_password.should == old
      end
    end
  end

end
