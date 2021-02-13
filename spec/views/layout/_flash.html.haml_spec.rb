#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe "layouts/_flash.html.haml" do
  let(:dom) { Capybara::Node::Simple.new(rendered) }

  subject { dom.find("p") }

  before do
    allow(view).to receive_messages(level: :info)
    controller.flash[:info] = info
    render
  end

  context "splits array into lines" do
    let(:info) { %w[foo bar] }

    its("native.to_xml") { is_expected.to =~ %r{<br/>} }
    its(:text) { is_expected.to eq "foo\nbar" }
  end

  context "does not escape html" do
    let(:info) { "<i>foo</i>" }

    its("native.to_xml") { is_expected.to =~ %r{<i>foo</i>} }
    its(:text) { is_expected.to eq "foo" }
  end
end
