#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "groups/_form.html.haml" do
  let(:group) { groups(:top_layer) }
  let(:stubs) {
    {model_class: Group, path_args: group,
     entry: GroupDecorator.new(group),}
  }

  before do
    allow(view).to receive_messages(stubs)
    allow(controller).to receive_messages(current_user: people(:top_leader))
  end

  it "does render contactable and extension partials" do
    partials = ["_error_messages", "_fields", "contactable/_fields",
                "contactable/_phone_number_fields", "_phone_number_fields",
                "contactable/_social_account_fields", "_social_account_fields",
                "groups/_form", "_form",]

    expect(view).to receive(:render_extensions).with(:address_fields, anything)
    expect(view).to receive(:render_extensions).with(:additional_fields, anything)
    expect(view).to receive(:render_extensions).with(:fields, anything)
    render partial: "groups/form"
    partials.each do |partial|
      expect(view).to render_template(partial: partial)
    end
  end
end
