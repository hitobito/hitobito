# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe FormatHelper do

  include I18nHelper
  include UtilityHelper
  include CrudTestHelper
  include NestedForm::ViewHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  # define some test format_ methods
  def format_size(obj)
    "#{f(obj.size)} items"
  end

  def format_string_size(obj)
    "#{f(obj.size)} chars"
  end

  describe "#labeled" do
    context "regular" do
      subject { labeled("label") { "value" } }

      it { is_expected.to be_html_safe }
      # its(:squish) { should == '<div class="labeled"> <label>label</label> <div class="value">value</div> </div>'.gsub('"', "'") }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>value</dd>'.gsub('"', "'") }
    end

    context "with empty value" do
      subject { labeled("label") { "" } }

      it { is_expected.to be_html_safe }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>'.gsub('"', "'") + FormatHelper::EMPTY_STRING + "</dd>" }
    end

    context "with unsafe value" do
      subject { labeled("label") { "value <unsafe>" } }

      it { is_expected.to be_html_safe }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>value &lt;unsafe&gt;</dd>'.gsub('"', "'") }
    end
  end

  describe "#labeled_attr" do
    subject { labeled_attr("foo", :size) }

    it { is_expected.to be_html_safe }
    its(:squish) {  should == '<dt class="muted">Size</dt> <dd>3 chars</dd>'.gsub('"', "'") }
  end

  describe "#f" do

    context "Fixnums" do
      it "should print small values unchanged" do
        expect(f(10)).to eq("10")
      end

      it "should print large values without delimiters" do
        expect(f(10_000_000)).to eq("10000000")
      end
    end

    context "Floats" do
      it "should add two digits" do
        expect(f(1.0)).to eq("1.00")
      end

      it "should truncate to two digits" do
        expect(f(3.14159)).to eq("3.14")
      end

      it "should add delimiters" do
        expect(f(12345.6789)).to eq("12&#39;345.68")
      end
    end

    context "Booleans" do
      it "true should print yes" do
        expect(f(true)).to eq("ja")
      end

      it "false should print no" do
        expect(f(false)).to eq("nein")
      end
    end

    context "nil" do
      it "should print an empty string" do
        expect(f(nil)).to eq(FormatHelper::EMPTY_STRING)
      end
    end

    context "Strings" do
      it "should print regular strings unchanged" do
        expect(f("blah blah")).to eq("blah blah")
      end

      it "should not be html safe" do
        expect(f("<injection>")).not_to be_html_safe
      end
    end

  end

  describe "#format_attr" do
    it "should use #f" do
      expect(format_attr("12.342", :to_f)).to eq(f(12.342))
    end

    it "should use object attr format method if it exists" do
      expect(format_attr("abcd", :size)).to eq("4 chars")
    end

    it "should use general attr format method if it exists" do
      expect(format_attr([1, 2], :size)).to eq("2 items")
    end

    it "should format empty belongs_to" do
      expect(format_attr(crud_test_models(:AAAAA), :companion)).to eq(t(:'global.associations.no_entry'))
    end

    it "should format existing belongs_to" do
      string = format_attr(crud_test_models(:BBBBB), :companion)
      expect(string).to eq("AAAAA")
    end

    it "should format existing has_many" do
      string = format_attr(crud_test_models(:CCCCC), :others)
      expect(string).to be_html_safe
      expect(string).to eq("<ul><li>AAAAA</li><li>BBBBB</li></ul>")
    end
  end

  describe "#fnumber" do
    context "Fixnums" do
      it "should print small values unchanged" do
        expect(fnumber(10)).to eq("10")
      end

      it "should print large values with delimiters" do
        expect(fnumber(10_000_000)).to eq("10&#39;000&#39;000")
      end
    end

    context "Floats" do
      it "should add two digits" do
        expect(fnumber(1.0)).to eq("1.00")
      end

      it "should truncate to two digits" do
        expect(fnumber(3.14159)).to eq("3.14")
      end

      it "should add delimiters" do
        expect(fnumber(12345.6789)).to eq("12&#39;345.68")
      end
    end

    context "nil" do
      it "should print an empty string" do
        expect(fnumber(nil)).to eq(FormatHelper::EMPTY_STRING)
      end
    end

    context "Strings" do
      it "should print small integer strings unchanged" do
        expect(fnumber("10")).to eq("10")
      end

      it "should print large integer strings with delimiters" do
        expect(fnumber("10000000")).to eq("10&#39;000&#39;000")
      end

      it "should convert any other string to integer" do
        expect(fnumber("blah blah")).to eq("0")
      end
    end
  end

  describe "#column_type" do
    let(:model) { crud_test_models(:AAAAA) }

    it "should recognize types" do
      expect(column_type(model, :name)).to eq(:string)
      expect(column_type(model, :children)).to eq(:integer)
      expect(column_type(model, :companion_id)).to eq(:integer)
      expect(column_type(model, :rating)).to eq(:float)
      expect(column_type(model, :income)).to eq(:decimal)
      expect(column_type(model, :birthdate)).to eq(:date)
      expect(column_type(model, :gets_up_at)).to eq(:time)
      expect(column_type(model, :last_seen)).to eq(:datetime)
      expect(column_type(model, :human)).to eq(:boolean)
      expect(column_type(model, :remarks)).to eq(:text)
      expect(column_type(model, :companion)).to be_nil

      # test translated models
      expect(column_type(event_kinds(:slk), :label)).to eq(:string)
      expect(column_type(event_kinds(:slk), :general_information)).to eq(:text)
    end
  end

  describe "#format_type" do
    let(:model) { crud_test_models(:AAAAA) }

    it "should format integers" do
      model.children = 10_000
      expect(format_type(model, :children)).to eq("10000")
    end

    it "should format floats" do
      expect(format_type(model, :rating)).to eq("1.10")
    end

    it "should format decimals" do
      expect(format_type(model, :income)).to eq("10&#39;000&#39;000.10")
    end

    it "should format dates" do
      expect(format_type(model, :birthdate)).to eq("01.01.1910")
    end

    it "should format times" do
      expect(format_type(model, :gets_up_at)).to eq("01:01")
    end

    it "should format datetimes" do
      expect(format_type(model, :last_seen)).to eq("01.01.2010 11:21")
    end

    it "should format texts" do
      string = format_type(model, :remarks)
      expect(string).to be_html_safe
      expect(string).to eq("<p>AAAAA BBBBB CCCCC\n<br />AAAAA BBBBB CCCCC\n</p>")
    end

    it "should escape texts" do
      model.remarks = "<unsecure>bla"
      string = format_type(model, :remarks)
      expect(string).to be_html_safe
      expect(string).to eq("<p>&lt;unsecure&gt;bla</p>")
    end

    it "should format empty texts" do
      model.remarks = "   "
      string = format_type(model, :remarks)
      expect(string).to be_html_safe
      expect(string).to eq(FormatHelper::EMPTY_STRING)
    end
  end

  describe "#content_tag_nested" do

    it "should escape safe content" do
      html = content_tag_nested(:div, %w(a b)) { |e| content_tag(:span, e) }
      expect(html).to be_html_safe
      expect(html).to eq("<div><span>a</span><span>b</span></div>")
    end

    it "should escape unsafe content" do
      html = content_tag_nested(:div, %w(a b)) { |e| "<#{e}>" }
      expect(html).to eq("<div>&lt;a&gt;&lt;b&gt;</div>")
    end

    it "should simply join without block" do
      html = content_tag_nested(:div, %w(a b))
      expect(html).to eq("<div>ab</div>")
    end
  end

  describe "#safe_join" do
    it "should works as super without block" do
      html = safe_join(["<a>", "<b>".html_safe])
      expect(html).to eq("&lt;a&gt;<b>")
    end

    it "should collect contents for array" do
      html = safe_join(%w(a b)) { |e| content_tag(:span, e) }
      expect(html).to eq("<span>a</span><span>b</span>")
    end
  end

  describe "#captionize" do
    it "should handle symbols" do
      expect(captionize(:camel_case)).to eq("Camel Case")
    end

    it "should render all upper case" do
      expect(captionize("all upper case")).to eq("All Upper Case")
    end

    it "should render human attribute name" do
      expect(captionize(:gets_up_at, CrudTestModel)).to eq("Gets up at")
    end
  end

  describe "#translate_inheritable" do
    before { @controller = CrudTestModelsController.new }

    before { I18n.backend.store_translations :de, global: { test_key: "global" } }
    subject { ti(:test_key) }

    it { is_expected.to eq("global") }

    context "with list key" do
      before { I18n.backend.store_translations :de, list: { global: { test_key: "list global" } } }
      it { is_expected.to eq("list global") }

      context "and list action key" do
        before { I18n.backend.store_translations :de, list: { index: { test_key: "list index" } } }
        it { is_expected.to eq("list index") }

        context "and crud global key" do
          before { I18n.backend.store_translations :de, crud: {  global: { test_key: "crud global" } } }
          it { is_expected.to eq("crud global") }

          context "and crud action key" do
            before { I18n.backend.store_translations :de, crud: {  index: { test_key: "crud index" } } }
            it { is_expected.to eq("crud index") }

            context "and controller global key" do
              before { I18n.backend.store_translations :de, crud_test_models: {  global: { test_key: "test global" } } }
              it { is_expected.to eq("test global") }

              context "and controller action key" do
                before { I18n.backend.store_translations :de, crud_test_models: {  index: { test_key: "test index" } } }
                it { is_expected.to eq("test index") }
              end
            end
          end
        end
      end
    end
  end

  describe "#translate_association" do
    let(:assoc) { CrudTestModel.reflect_on_association(:companion) }
    subject { ta(:test_key, assoc) }

    before { I18n.backend.store_translations :de, global: { associations: { test_key: "global" } } }
    it { is_expected.to eq("global") }

    context "with model key" do
      before do
        I18n.backend.store_translations :de,
                                        activerecord: {
                                          associations: {
                                            crud_test_model: {
                                              test_key: "model" } } }
      end

      it { is_expected.to eq("model") }

      context "and assoc key" do
        before do
          I18n.backend.store_translations :de,
                                          activerecord: {
                                            associations: {
                                              models: {
                                                crud_test_model: {
                                                  companion: {
                                                    test_key: "companion" } } } } }
        end

        it { is_expected.to eq("companion") }
        it "should use global without assoc" do
          expect(ta(:test_key)).to eq("global")
        end
      end
    end
  end
end
