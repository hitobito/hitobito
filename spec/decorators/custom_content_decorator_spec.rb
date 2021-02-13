# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"
describe CustomContentDecorator, :draper_with_helpers  do
  let(:decorator) { CustomContentDecorator.new(content) }

  context "#available_placeholders" do
    subject { decorator.available_placeholders }

    context "placeholders present" do
      let(:content)   { custom_contents(:login) }

      it "lists available placeholders in string" do
        is_expected.to eq "Verfügbare Platzhalter: {login-url}, {recipient-name}, {sender-name}"
      end
    end

    context "placeholders missing" do
      let(:content)   { CustomContent.new }

      it "informs when no placeholders are available" do
        is_expected.to eq "Keine Platzhalter vorhanden"
      end
    end
  end

end
