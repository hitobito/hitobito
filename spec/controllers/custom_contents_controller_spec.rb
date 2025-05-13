#  Copyright (c) 2012-2015, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe CustomContentsController do
  let(:layer_custom_content) { Fabricate(:custom_content, context: Group.root) }

  before { sign_in(people(:top_leader)) }

  describe "#index" do
    it "should not contain layer specific entries" do
      get :index
      expect(assigns(:custom_contents)).not_to include(layer_custom_content)
    end
  end
end
