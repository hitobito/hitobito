require 'spec_helper'


describe ListHelper do

  include StandardHelper
  include CrudTestHelper
  
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
        subject.scan(REGEXP_ROWS).size.should == 7
      end
      
      it "should have 13 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 13
      end
    end
    
    context "with custom attributes" do
      subject do
        with_test_routing { list_table(:name, :children, :companion_id) }
      end
      
      it "should have 7 rows" do
        subject.scan(REGEXP_ROWS).size.should == 7
      end
      
      it "should have 3 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 3
      end
    end

    context "with custom block" do
      subject do
        with_test_routing do
          list_table do |t|
            t.attrs :name, :children, :companion_id
            t.col('head') {|e| content_tag(:span, e.income.to_s) }
          end
        end
      end
      
      it "should have 7 rows" do
        subject.scan(REGEXP_ROWS).size.should == 7
      end
      
      it "should have 4 headers" do
        subject.scan(REGEXP_HEADERS).size.should == 4
      end
      
      it "should have 0 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 0
      end
      
      it "should have 6 spans" do
        subject.scan(/<span>.+?<\/span>/).size.should == 6
      end
    end
    
    context "with custom attributes and block" do
      subject do
        with_test_routing do
          list_table(:name, :children, :companion_id) do |t|
            t.col('head') {|e| content_tag(:span, e.income.to_s) }
          end
        end
      end
      
      it "should have 7 rows" do
        subject.scan(REGEXP_ROWS).size.should == 7
      end
      
      it "should have 4 headers" do
        subject.scan(REGEXP_HEADERS).size.should == 4
      end
      
      it "should have 3 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 3
      end
      
      it "should have 6 spans" do
        subject.scan(/<span>.+?<\/span>/).size.should == 6
      end
    end
    
    context "with ascending sort params" do
      let(:params) { {:sort => 'children', :sort_dir => 'asc'} }
      subject do
        with_test_routing { list_table }
      end

      it "should have 12 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 12
      end
      
      it "should have 1 ascending sort headers" do
        subject.scan(/<th><a .*?sort_dir=desc.*?>Children<\/a> &darr;<\/th>/).size.should == 1
      end
    end
    
    context "with descending sort params" do
      let(:params) { {:sort => 'children', :sort_dir => 'desc'} }
      subject do
        with_test_routing { list_table }
      end

      it "should have 12 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 12
      end
      
      it "should have 1 descending sort headers" do
        subject.scan(/<th><a .*?sort_dir=asc.*?>Children<\/a> &uarr;<\/th>/).size.should == 1
      end
    end
    
    context "with custom column sort params" do
      let(:params) { {:sort => 'chatty', :sort_dir => 'asc'} }
      subject do
        with_test_routing { list_table(:name, :children, :chatty) }
      end

      it "should have 2 sortable headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 2
      end
      
      it "should have 1 ascending sort headers" do
        subject.scan(/<th><a .*?sort_dir=desc.*?>Chatty<\/a> &darr;<\/th>/).size.should == 1
      end
    end
  end
  
  describe "#default_attrs" do
    it "should not contain id" do
      default_attrs.should == [:name, :whatever, :children, :companion_id, :rating, :income,
                               :birthdate, :gets_up_at, :last_seen, :human, :remarks,
                               :created_at, :updated_at]
      end
  end
end
