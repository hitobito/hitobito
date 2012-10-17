require 'spec_helper'

describe EventsController, type: :controller do
  
  # always use fixtures with crud controller examples, otherwise request reuse might produce errors
  let(:test_entry) { events(:top_course) }
  let(:test_entry_attrs) { { name: 'Chief Leader Course' } }

  before { sign_in(people(:top_leader)) } 

  include_examples 'crud controller', skip: [%w(index), %w(new), %w(create), %w(edit), %w(update), %w(destroy)]


end
