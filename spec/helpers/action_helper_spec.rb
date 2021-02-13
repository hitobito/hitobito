# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"


describe ActionHelper do

  include LayoutHelper
  include I18nHelper
  include UtilityHelper
  include ActionHelper
  include FormatHelper
  include CrudTestHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }


  describe "#button_action_destroy" do
    let(:entry) { people(:top_leader) }

    context "without options" do
      subject do
        button_action_destroy
      end

      it "should contain person path" do
        is_expected.to have_selector("a[href='/people/#{entry.id}']")
      end

      it "should have method delete" do
        is_expected.to have_selector("a[data-method=delete]")
      end

      it "should have standard prompt" do
        is_expected.to have_selector("a[data-confirm='#{ti(:confirm_delete)}']")
      end
    end

    context "with options" do
      it "should override data-confirm" do
        label = t("person.confirm_delete", person: entry)
        button = button_action_destroy(nil, { data: { confirm: label }})
        expect(button).to have_selector("a[data-confirm='#{label}']")
        expect(button).to have_selector("a[data-method='delete']")
      end

      it "should override data-method" do
        button = button_action_destroy(nil, { data: { method: :put }})
        expect(button).to have_selector("a[data-method=put]")
        expect(button).to have_selector("a[data-confirm='Wollen Sie diesen Eintrag wirklich löschen?']")
      end

      it "should override path" do
        button = button_action_destroy("/sample_path")
        expect(button).to have_selector("a[href='/sample_path']")
        expect(button).to have_selector("a[data-method='delete']")
      end
    end
  end
end
