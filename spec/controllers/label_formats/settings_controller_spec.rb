# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe LabelFormat::SettingsController do

  let(:user) { people(:top_leader) }

  context "PUT :update" do
    render_views

    it "renders update.js" do
      sign_in(user)

      put :update, params: { show_global_label_formats: "" }, format: :js

      is_expected.to render_template("update")
    end

    it "sets flag to false if param empty" do
      sign_in(user)

      put :update, params: { show_global_label_formats: "" }, format: :js
      user.reload
      expect(user.show_global_label_formats).to be_falsey
    end

    it "sets flag to true if param not empty" do
      sign_in(user)

      put :update, params: { show_global_label_formats: "true" }, format: :js
      user.reload
      expect(user.show_global_label_formats).to be_truthy
    end
  end

end
