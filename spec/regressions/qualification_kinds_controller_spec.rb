# encoding:  utf-8

require 'spec_helper'

describe QualificationKindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to qualification_kinds_path } 
    end
  end

  let(:test_entry) { qualification_kinds(:sl) }
  let(:test_entry_attrs) { { label: 'Super Leader', description: 'More bla', validity: 3 } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show)]

end
