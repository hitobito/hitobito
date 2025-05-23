#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe CustomContentDecorator, :draper_with_helpers do
  let(:decorator) { CustomContentDecorator.new(content) }

  context "#available_placeholders" do
    subject { decorator.available_placeholders }

    context "placeholders present" do
      let(:content) { custom_contents(:login) }

      it "lists available placeholders in string" do
        is_expected.to eq "Verfügbare Platzhalter: {login-url}, {recipient-name}, {sender-name}"
      end
    end

    context "placeholders missing" do
      let(:content) { CustomContent.new }

      it "informs when no placeholders are available" do
        is_expected.to eq "Keine Platzhalter vorhanden"
      end
    end

    context "custom_content with context" do
      let(:content) { CustomContent.new(context: Group.root, key: custom_contents(:login).key) }

      it "lists available placeholders from global custom content in string" do
        is_expected.to eq "Verfügbare Platzhalter: {login-url}, {recipient-name}, {sender-name}"
      end
    end
  end
end
