# frozen_string_literal: true

#  Copyright (c) 2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe HelpTextsController do
  let(:top_leader) { people(:top_leader) }

  before { sign_in(top_leader) }

  context 'POST create' do
    it 'creates help text and translation' do
      attrs = { context: 'mailing_lists--mailing_list',
                key: 'field.name',
                body: '<div>designation of the mailing list</div>' }
      expect do
        post :create, xhr: true, params: { help_text: attrs  }
      end.to change { HelpText.count }.by(1)
         .and change { HelpText::Translation.count }.by(1)

    end
  end

end
