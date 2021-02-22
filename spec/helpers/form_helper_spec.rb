#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FormHelper do
  include ActionHelper
  include I18nHelper
  include TableHelper
  include UtilityHelper
  include LayoutHelper
  include FormatHelper
  include CrudTestHelper
  include NestedForm::ViewHelper
  include HelpTextsHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  describe "#entry_form" do
    let(:entry) { CrudTestModel.first }

    subject do
      with_test_routing { Capybara::Node::Simple.new(entry_form) }
    end

    it "should contain form tag" do
      is_expected.to have_selector("form[action='/crud_test_models/#{entry.id}']")
    end

    it "should contain input for name" do
      # is_expected.to match /input [^>]*?name="crud_test_model\[name\]" [^>]*?type="text"/
      is_expected.to have_selector('input[name="crud_test_model[name]"][type=text]')
    end

    it "should contain input for whatever" do
      is_expected.to have_selector('input[name="crud_test_model[whatever]"][type=text]')
    end

    it "should contain input for children" do
      is_expected.to have_selector('input[name="crud_test_model[children]"][type=text]')
    end

    it "should contain input for rating" do
      is_expected.to have_selector('input[name="crud_test_model[rating]"][type=text]')
    end

    it "should contain input for income" do
      is_expected.to have_selector('input[name="crud_test_model[income]"][type=text]')
    end

    it "should contain input for birthdate" do
      is_expected.to have_selector('input[name="crud_test_model[birthdate]"]')
    end

    it "should contain input for human" do
      is_expected.to have_selector('input[name="crud_test_model[human]"][type=checkbox]')
    end

    it "should contain input for companion" do
      is_expected.to have_selector('select[name="crud_test_model[companion_id]"]')
    end

    it "should contain input for remarks" do
      is_expected.to have_selector('textarea[name="crud_test_model[remarks]"]')
    end
  end

  describe "#crud_form" do
    subject do
      Capybara::Node::Simple.new(
        with_test_routing {
          capture { crud_form(entry, :name, :children, :birthdate, :human, html: {class: "special"}) }
        }
      )
    end

    context "for existing entry" do
      let(:entry) { crud_test_models(:AAAAA) }

      it { is_expected.to have_selector("form.special.form-horizontal[action='/crud_test_models/#{entry.id}'][method=post]") }
      it { is_expected.to have_selector("input[name=_method][type=hidden][value=patch]", visible: false) }
      it { is_expected.to have_selector("input[name='crud_test_model[name]'][type=text][value=AAAAA]") }
      it { is_expected.to have_selector("input[name='crud_test_model[birthdate]'][type=text][value='01.01.1910']") }
      it { is_expected.to have_selector("input[name='crud_test_model[children]'][type=text][value='9']") }
      it { is_expected.to have_selector("input[name='crud_test_model[human]'][type=checkbox]") }
      it { is_expected.to have_selector("button[type=submit]") }
    end

    context "for new entry" do
      let(:entry) { CrudTestModel.new }

      it { is_expected.to have_selector("form.special.form-horizontal[action='/crud_test_models'][method=post]") }
      it { is_expected.to have_selector("input[name='crud_test_model[name]'][type=text]") }
      it { is_expected.to have_no_selector("input[name='crud_test_model[name]'][type=text][value]") }
      it { is_expected.to have_selector("input[name='crud_test_model[birthdate]'][type=text]") }
      it { is_expected.to have_selector("input[name='crud_test_model[children]'][type=text]") }
      it { is_expected.to have_no_selector("input[name='crud_test_model[children]'][type=text][value]") }
      it { is_expected.to have_selector("button[type=submit]") }
    end

    context "for invalid entry" do
      let(:entry) do
        e = crud_test_models(:AAAAA)
        e.name = nil
        e.valid?
        e
      end

      it { is_expected.to have_selector("div#error_explanation") }
      it { is_expected.to have_selector("div.control-group.error input[name='crud_test_model[name]'][type=text]") }
      it { is_expected.to have_selector("input[name=_method][type=hidden][value=patch]", visible: false) }
    end
  end

  describe "#standard_form" do
    subject do
      Capybara::Node::Simple.new(
        with_test_routing {
          capture { standard_form(entry, html: {class: "special"}) { |f| } }
        }
      )
    end

    let(:entry) { crud_test_models(:AAAAA) }

    it { is_expected.to have_selector("form.form-horizontal.special[method=post][action='/crud_test_models/#{entry.id}']") }
  end
end
