# encoding: UTF-8
require 'spec_helper'

describe Devise::RegistrationsController do
  before { request.env['devise.mapping'] = Devise.mappings[:person] }
  render_views

  let(:person) { people(:top_leader) }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  before { sign_in(person) }

  def prepare(hash={})
    person.update_column(:encrypted_password, nil) if hash[:reset_password]
    sign_in(person)
    yield
  end

  describe "GET #edit" do
    subject { dom }

    context "user with password" do
      before { prepare { get :edit }  }

      it { should have_content 'Passwort ändern' }
      it { should have_content 'Altes Passwort' }
    end

    context "user without password" do
      before { prepare(reset_password: true) { get :edit } }

      it { should have_content 'Passwort setzen' }
      it { should_not have_content 'Altes Passwort' }
    end
  end

  describe "put #update" do
    let(:data) { { passsword: 'foobar', password_confirmation: 'foobar' } }

    context "without with password" do
      subject { dom }
      before { prepare { put :update, person: data }  }

      it { should have_content 'Altes Passwort muss ausgefüllt werden' }
    end


    context "user without password" do
      before { prepare(reset_password: true) { put :update, person: data }  }

      it { should_not have_content 'Altes Passwort muss ausgefüllt werden' }
      it { flash[:notice].should eq 'Deine Daten wurden aktualisiert.' }
    end

    
  end

end
