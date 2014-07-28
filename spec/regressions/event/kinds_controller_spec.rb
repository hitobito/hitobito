# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# encoding:  utf-8

require 'spec_helper'

describe Event::KindsController, type: :controller do

  class << self
    def it_should_redirect_to_show
      it { should redirect_to event_kinds_path(returning: true) }
    end
  end

  let(:test_entry) { event_kinds(:slk) }
  let(:test_entry_attrs) do { label: 'Automatic Bar Course',
                              short_name: 'ABC',
                              minimum_age: 21 } end

  before { sign_in(people(:top_leader)) }

  include_examples 'crud controller', skip: [%w(show), %w(destroy)]

  it 'soft deletes' do
    expect { post :destroy, id: test_entry.id }.to change { Event::Kind.without_deleted.count }.by(-1)
  end

end
