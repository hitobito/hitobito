# encoding:  utf-8

require 'spec_helper'

describe Event::KindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to event_kinds_path(returning: true) } 
    end
  end

  let(:test_entry) { Event::Kind.first }
  let(:test_entry_attrs) { { label: 'Automatic Bar Course',
                             short_name: 'ABC',
                             minimum_age: 21,
                             j_s_label: 'Automatic J+S Bar Course' } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(show), %w(destroy)]

end
