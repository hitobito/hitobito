#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "contactable/_fields.html.haml" do
  let(:group) { groups(:top_layer) }
  let(:current_user) { people(:top_leader) }
  let(:form_builder) { StandardFormBuilder.new(:group, group, view, {}) }

  subject { Capybara::Node::Simple.new(@rendered).find("fieldset.info", visible: false) }

  before do
    controller.controller_path = "groups"
    controller.request.path_parameters[:controller] = "groups"
    view.extend FormatHelper
    allow(view).to receive_messages(entry: GroupDecorator.decorate(group), f: form_builder)

    # mock render call to email_field partial
    render_method = view.method(:render)
    expect(view).to receive(:render) { |*args|
      if args == ["email_field", f: form_builder]
        ""
      else
        render_method.call(*args)
      end
    }.exactly(4).times
  end

  context "standard" do
    before { render }

    its([:style]) { should be_blank }
  end

  context "when contact is set" do
    before do
      group.contact = current_user
      render
    end

    its([:style]) { should eq "display: none" }
  end
end
