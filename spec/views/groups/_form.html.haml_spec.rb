require 'spec_helper'
describe "groups/_form.html.haml" do
  let(:group) { groups(:top_layer) }
  before { view.stub(model_class: Group, path_args: group) }
  before { view.stub(entry: GroupExhibit.new(group, view)) }

  it "does render contactable and extension partials" do
    partials = ["_error_messages", "_fields", "contactable/_fields",
                "contactable/_phone_number_fields", "_phone_number_fields",
                "contactable/_social_account_fields", "_social_account_fields",
                "groups/_form", "_form"]

    view.should_receive(:render_extensions).with(:fields, anything)
    render partial: 'groups/form'
    partials.each do |partial|
      expect(view).to render_template(partial: partial)
    end
  end
end
