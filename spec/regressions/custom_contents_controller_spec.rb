# encoding:  utf-8

require 'spec_helper'

describe CustomContentsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to custom_contents_path(returning: true) } 
    end
  end

  let(:test_entry) { custom_contents(:login) }
  let(:test_entry_attrs) { { subject: 'New Login', body: "Hej {user}, go here to login: {login-url}" } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show), %w(new), %w(create), %w(destroy)]

end
