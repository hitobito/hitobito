# frozen_string_literal: true

#  Copyright (c) 2012-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe "StandardFormBuilder" do
  include FormatHelper
  include I18nHelper
  include FormHelper
  include UtilityHelper
  include CrudTestHelper
  include LayoutHelper
  include HelpTextsHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  let(:entry) { CrudTestModel.first }
  let(:form) { StandardFormBuilder.new(:entry, entry, self, {}) }

  describe "#input_field" do
    {name: :string_field,
     password: :password_field,
     remarks: :text_area,
     children: :integer_field,
     human: :boolean_field,
     birthdate: :date_field,
     gets_up_at: :time_field,
     companion_id: :belongs_to_field,
     other_ids: :has_many_field,
     more_ids: :has_many_field}.each do |attr, method|
      it "dispatches #{attr} attr to #{method}" do
        expect(form).to receive(method).with(attr, {class: ""})
        form.input_field(attr)
      end

      it { expect(form.input_field(attr)).to be_html_safe }
    end
  end

  describe "#labeled_input_fields" do
    subject { form.labeled_input_fields(:name, :remarks, :children) }

    it { is_expected.to be_html_safe }
    it { is_expected.to include(form.input_field(:name)) }
    it { is_expected.to include(form.input_field(:remarks)) }
    it { is_expected.to include(form.input_field(:children)) }
  end

  describe "#labeled_input_field" do
    context "when required" do
      subject { form.labeled_input_field(:name) }

      it { is_expected.to include('class="col-md-3 col-xl-2 pb-1 col-form-label text-md-end required"') }
    end

    context "when not required" do
      subject { form.labeled_input_field(:remarks) }

      it { is_expected.not_to include('class="control-group required"') }
    end

    context "with help text" do
      subject { form.labeled_input_field(:name, help: "Some Help") }

      it { is_expected.to include(form.help_block("Some Help")) }
    end

    context "with label" do
      subject { form.labeled_input_field(:name, label: "Some Caption") }

      it { is_expected.to include(form.label(:name, "Some Caption", class: "col-md-3 col-xl-2 pb-1 col-form-label text-md-end required")) }
    end

    context "with addon" do
      subject { form.labeled_input_field(:name, addon: "Some Addon") }

      it { is_expected.to match(/class="input-group-text"/) }
      it { is_expected.to match(/Some Addon/) }
    end

    context "with label_class" do
      subject { form.labeled_input_field(:name, label: "Some Caption", label_class: "custom-class") }

      it { is_expected.to include(form.label(:name, "Some Caption", class: "custom-class col-form-label text-md-end required")) }
    end
  end

  describe "#belongs_to_field" do
    it "has all options by default" do
      f = form.belongs_to_field(:companion_id)
      expect(f.scan("</option>").size).to eq(7)
    end

    it "with has options from :list option" do
      list = CrudTestModel.all
      f = form.belongs_to_field(:companion_id, list: [list.first, list.second])
      expect(f.scan("</option>").size).to eq(3)
    end

    it "with empty instance list has no select" do
      assign(:companions, [])
      @companions = []
      f = form.belongs_to_field(:companion_id)
      expect(f).to match(/keine verfügbar/m)
      expect(f.scan("</option>").size).to eq(0)
    end
  end

  describe "#has_and_belongs_to_many_field" do
    let(:others) { OtherCrudTestModel.all[0..1] }

    it "has all options by default" do
      f = form.has_many_field(:other_ids)
      expect(f.scan("</option>").size).to eq(6)
    end

    it "uses options from :list option if given" do
      f = form.has_many_field(:other_ids, list: others)
      expect(f.scan("</option>").size).to eq(2)
    end

    it "uses options form instance variable if given" do
      assign(:others, others)
      @others = others
      f = form.has_many_field(:other_ids)
      expect(f.scan("</option>").size).to eq(2)
    end

    it "displays a message for an empty list" do
      @others = []
      f = form.has_many_field(:other_ids)
      expect(f).to match(/keine verfügbar/m)
      expect(f.scan("</option>").size).to eq(0)
    end
  end

  describe "#string_field" do
    it "sets maxlength if attr has a limit" do
      expect(form.string_field(:name)).to match(/maxlength="50"/)
    end
  end

  describe "#country_field" do
    let(:entry) { OpenStruct.new(country: nil) }

    it "uses stimulus controller to setup tom-select" do
      html = Capybara::Node::Simple.new(
        form.country_field(:country)
      )
      select = html.find("select")

      expect(select[:class]).not_to include("tom-select")
      expect(select["data-controller"]).to match(/\btom-select\b/)
    end
  end

  describe "#date_field" do
    it "sets empty date value" do
      entry.update_column(:birthdate, nil)
      entry.reload
      expect(form.date_field(:birthdate)).not_to match(/value=/)
    end

    it "sets original date value" do
      entry.update_column(:birthdate, Date.new(2000, 1, 1))
      entry.reload
      expect(form.date_field(:birthdate)).to match(/value="01.01.2000"/)
    end

    it "sets changed valid date value" do
      entry.birthdate = "1.1.00"
      expect(form.date_field(:birthdate)).to match(/value="01.01.2000"/)
    end

    it "sets changed invalid date value" do
      entry.birthdate = "31.12.10000"
      expect(form.date_field(:birthdate)).to match(/value="31.12.10000"/)
    end
  end

  describe "#label" do
    context "only with attr" do
      subject { form.label(:gugus_dada) }

      it { is_expected.to be_html_safe }
      it "provides the same interface as rails" do
        is_expected.to match(/label [^>]*for.+Gugus dada/)
      end
    end

    context "with attr and text" do
      subject { form.label(:gugus_dada, "hoho") }

      it { is_expected.to be_html_safe }
      it "provides the same interface as rails" do
        is_expected.to match(/label [^>]*for.+hoho/)
      end
    end
  end

  describe "#labeled" do
    context "in labeled_ method" do
      subject { form.labeled_string_field(:name) }

      it { is_expected.to be_html_safe }
      it "provides the same interface as rails" do
        is_expected.to match(/label [^>]*for.+input/m)
      end
    end

    context "with custom content in argument" do
      subject { form.labeled("gugus", "<input type='text' name='gugus' />".html_safe) }

      it { is_expected.to be_html_safe }
      it { is_expected.to match(/label [^>]*for.+<input/m) }
    end

    context "with custom content in block" do
      subject { form.labeled("gugus") { "<input type='text' name='gugus' />".html_safe } }

      it { is_expected.to be_html_safe }
      it { is_expected.to match(/label [^>]*for.+<input/m) }
    end

    context "with caption and content in argument" do
      subject { form.labeled("gugus", "Caption", "<input type='text' name='gugus' />".html_safe) }

      it { is_expected.to be_html_safe }
      it { is_expected.to match(/label [^>]*for.+>Caption<\/label>.*<input/m) }
    end

    context "with caption and content in block" do
      subject { form.labeled("gugus", "Caption") { "<input type='text' name='gugus' />".html_safe } }

      it { is_expected.to be_html_safe }
      it { is_expected.to match(/label [^>]*for.+>Caption<\/label>.*<input/m) }
    end
  end

  it "handles missing methods" do
    expect { form.blabla }.to raise_error(NoMethodError)
  end

  context "#respond_to?" do
    it "returns false for non existing methods" do
      expect(form.respond_to?(:blabla)).to be_falsey
    end

    it "returns true for existing methods" do
      expect(form.respond_to?(:text_field)).to be_truthy
    end

    it "returns true for labeled_ methods" do
      expect(form.respond_to?(:labeled_text_field)).to be_truthy
    end
  end

  context "open-struct as entry" do
    let(:entry) do
      OpenStruct.new(
        cutoff_date: nil,
        cutoff_date_type: :date,
        amount: nil,
        amount_type: :number
      )
    end

    it "ignores errors_on" do
      expect(form.send(:errors_on?, :cutoff_date)).to be_falsey
    end
  end
end
