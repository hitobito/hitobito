#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe TableHelper do
  include LayoutHelper
  include I18nHelper
  include UtilityHelper
  include ActionHelper
  include FormatHelper
  include CrudTestHelper

  def can?(*args)
    true
  end

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  describe "#list_table" do
    let(:entries) { CrudTestModel.all }

    context "default" do
      subject do
        with_test_routing { list_table }
      end

      it "should have 7 rows" do
        expect(subject.scan(REGEXP_ROWS).size).to eq(7)
      end

      it "should have 13 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(13)
      end
    end

    context "with custom attributes" do
      subject do
        with_test_routing { list_table(:name, :children, :companion_id) }
      end

      it "should have 7 rows" do
        expect(subject.scan(REGEXP_ROWS).size).to eq(7)
      end

      it "should have 3 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(3)
      end
    end

    context "with custom block" do
      subject do
        with_test_routing do
          list_table do |t|
            t.attrs :name, :children, :companion_id
            t.col("head") { |e| content_tag(:span, e.income.to_s) }
          end
        end
      end

      it "should have 7 rows" do
        expect(subject.scan(REGEXP_ROWS).size).to eq(7)
      end

      it "should have 4 headers" do
        expect(subject.scan(REGEXP_HEADERS).size).to eq(4)
      end

      it "should have 0 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(0)
      end

      it "should have 6 spans" do
        expect(subject.scan(/<span>.+?<\/span>/).size).to eq(6)
      end
    end

    context "with custom attributes and block" do
      subject do
        with_test_routing do
          list_table(:name, :children, :companion_id) do |t|
            t.col("head") { |e| content_tag(:span, e.income.to_s) }
          end
        end
      end

      it "should have 7 rows" do
        expect(subject.scan(REGEXP_ROWS).size).to eq(7)
      end

      it "should have 4 headers" do
        expect(subject.scan(REGEXP_HEADERS).size).to eq(4)
      end

      it "should have 3 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(3)
      end

      it "should have 6 spans" do
        expect(subject.scan(/<span>.+?<\/span>/).size).to eq(6)
      end
    end

    context "with ascending sort params" do
      let(:params) { {sort: "children", sort_dir: "asc"} }

      subject do
        with_test_routing { list_table }
      end

      it "should have 12 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(12)
      end

      it "should have 1 ascending sort headers" do
        expect(subject.scan(/<th><a .*?sort_dir=desc.*?>Children<\/a> &darr;<\/th>/).size).to eq(1)
      end
    end

    context "with descending sort params" do
      let(:params) { {sort: "children", sort_dir: "desc"} }

      subject do
        with_test_routing { list_table }
      end

      it "should have 12 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(12)
      end

      it "should have 1 descending sort headers" do
        expect(subject.scan(/<th><a .*?sort_dir=asc.*?>Children<\/a> &uarr;<\/th>/).size).to eq(1)
      end
    end

    context "with custom column sort params" do
      let(:params) { {sort: "chatty", sort_dir: "asc"} }

      subject do
        with_test_routing { list_table(:name, :children, :chatty) }
      end

      it "should have 2 sortable headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(2)
      end

      it "should have 1 ascending sort headers" do
        expect(subject.scan(/<th><a .*?sort_dir=desc.*?>Chatty<\/a> &darr;<\/th>/).size).to eq(1)
      end
    end
  end

  describe "#default_attrs" do
    it "should not contain id" do
      expect(default_attrs).to eq([:name, :whatever, :children, :companion_id, :rating, :income,
                                   :birthdate, :gets_up_at, :last_seen, :human, :remarks,
                                   :created_at, :updated_at,])
    end
  end

  describe "#crud_table" do
    let(:entries) { CrudTestModel.all }

    context "default" do
      subject do
        with_test_routing { crud_table }
      end

      it "should have 7 rows" do
        expect(subject.scan(REGEXP_ROWS).size).to eq(7)
      end

      it "should have 13 sort headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(13)
      end

      it "should have 12 action cells" do
        expect(subject.scan(REGEXP_ACTION_CELL).size).to eq(12)
      end
    end

    context "with custom attrs" do
      subject do
        with_test_routing { crud_table(:name, :children, :companion_id) }
      end

      it "should have 3 sort headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(3)
      end
    end

    context "with custom block" do
      subject do
        with_test_routing do
          crud_table do |t|
            t.attrs :name, :children, :companion_id
            t.col("head") { |e| content_tag :span, e.income.to_s }
          end
        end
      end

      it "should have 4 headers" do
        expect(subject.scan(REGEXP_HEADERS).size).to eq(4)
      end

      it "should have 6 custom col spans" do
        expect(subject.scan(/<span>.+?<\/span>/m).size).to eq(6)
      end

      it "should have 0 action cells" do
        expect(subject.scan(REGEXP_ACTION_CELL).size).to eq(0)
      end
    end

    context "with custom attributes and block" do
      subject do
        with_test_routing do
          crud_table(:name, :children, :companion_id) do |t|
            t.col("head") { |e| content_tag :span, e.income.to_s }
          end
        end
      end

      it "should have 3 sort headers" do
        expect(subject.scan(REGEXP_SORT_HEADERS).size).to eq(3)
      end

      it "should have 6 custom col spans" do
        expect(subject.scan(/<span>.+?<\/span>/m).size).to eq(6)
      end

      it "should have 0 action cells" do
        expect(subject.scan(REGEXP_ACTION_CELL).size).to eq(0)
      end
    end
  end

  describe "#table" do
    context "with empty data" do
      subject { table([]) }

      it { is_expected.to be_html_safe }

      it "should handle empty data" do
        is_expected.to match(/Keine Eintr/)
      end
    end

    context "with data" do
      subject { table(%w[foo bar], :size) { |t| t.attrs :upcase } }

      it { is_expected.to be_html_safe }

      it "should render table" do
        is_expected.to match(/^\<div class="table-responsive"\>\<table.*\<\/table\>\<\/div\>$/)
      end

      it "should contain attrs" do
        is_expected.to match(/<th>Size<\/th>/)
      end

      it "should contain block" do
        is_expected.to match(/<th>Upcase<\/th>/)
      end
    end
  end
end
