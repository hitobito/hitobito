require 'spec_helper'

  
describe CrudHelper do
  
  include StandardHelper
  include ListHelper
  include CrudTestHelper
  include NestedForm::ViewHelper
  
    
  before do 
    reset_db
    setup_db
    create_test_data
  end
  
  after { reset_db }
  
  
  describe "#crud_table" do
    let(:entries) { CrudTestModel.all }
    
    context "default" do
      subject do
        with_test_routing { crud_table }
      end
      
      it "should have 7 rows" do
        subject.scan(REGEXP_ROWS).size.should == 7
      end
      
      it "should have 13 sort headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 13
      end
      
      it "should have 18 action cells" do
        subject.scan(REGEXP_ACTION_CELL).size.should == 18
      end
    end
    
    context "with custom attrs" do
      subject do
        with_test_routing { crud_table(:name, :children, :companion_id) }
      end
      
      it "should have 3 sort headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 3
      end
    end
    
    context "with custom block" do
      subject do
        with_test_routing do
          crud_table do |t|
            t.attrs :name, :children, :companion_id
            t.col("head") {|e| content_tag :span, e.income.to_s }
          end
        end
      end
      
      it "should have 4 headers" do
        subject.scan(REGEXP_HEADERS).size.should == 4
      end
      
      it "should have 6 custom col spans" do
        subject.scan(/<span>.+?<\/span>/m).size.should == 6
      end
      
      it "should have 0 action cells" do
        subject.scan(REGEXP_ACTION_CELL).size.should == 0
      end
    end
    
    context "with custom attributes and block" do
      subject do
        with_test_routing do
          crud_table(:name, :children, :companion_id) do |t|
            t.col("head") {|e| content_tag :span, e.income.to_s }
          end
        end
      end
      
      it "should have 3 sort headers" do
        subject.scan(REGEXP_SORT_HEADERS).size.should == 3
      end
      
      it "should have 6 custom col spans" do
        subject.scan(/<span>.+?<\/span>/m).size.should == 6
      end
      
      it "should have 0 action cells" do
        subject.scan(REGEXP_ACTION_CELL).size.should == 0
      end
    end
  end
  
  describe "#entry_form" do
    let(:entry) { CrudTestModel.first }
    
    subject do
      with_test_routing { entry_form }
    end
    
    it "should contain form tag" do
      should match /form .*?action="\/crud_test_models\/#{entry.id}"/
    end
    
    it "should contain input for name" do
      should match /input .*?name="crud_test_model\[name\]" .*?type="text"/
    end
    
    it "should contain input for whatever" do
      should match /input .*?name="crud_test_model\[whatever\]" .*?type="text"/
    end
    
    it "should contain input for children" do
      should match /input .*?name="crud_test_model\[children\]" .*?type="text"/
    end
    
    it "should contain input for rating" do
      should match /input .*?name="crud_test_model\[rating\]" .*?type="text"/
    end
    
    it "should contain input for income" do
      should match /input .*?name="crud_test_model\[income\]" .*?type="text"/
    end
    
    it "should contain input for birthdate" do
      should match /select .*?name="crud_test_model\[birthdate\(1i\)\]"/
    end
    
    it "should contain input for human" do
      should match /input .*?name="crud_test_model\[human\]" .*?type="checkbox"/
    end
    
    it "should contain input for companion" do
      should match /select .*?name="crud_test_model\[companion_id\]"/
    end
    
    it "should contain input for remarks" do
      should match /textarea .*?name="crud_test_model\[remarks\]"/
    end
   
  end
    
  describe "#crud_form" do
    subject do
      with_test_routing do
        capture { crud_form(entry, :name, :children, :birthdate, :human, :html => {:class => 'special'}) }
      end
    end
    
    context "for existing entry" do
      let(:entry) { crud_test_models(:AAAAA) }
      
      it { should match(/form .*?action="\/crud_test_models\/#{entry.id}" .?class="special form-horizontal" .*?method="post"/) }
      it { should match(/input .*?name="_method" .*?type="hidden" .*?value="put"/) }
      it { should match(/input .*?name="crud_test_model\[name\]" .*?type="text" .*?value="AAAAA"/) }
      it { should match(/select .*?name="crud_test_model\[birthdate\(1i\)\]"/) }
      it { should match(/option selected="selected" value="1910">1910<\/option>/) }
      it { should match(/option selected="selected" value="1">Januar<\/option>/) }
      it { should match(/option selected="selected" value="1">1<\/option>/) }
      it { should match(/input .*?name="crud_test_model\[children\]" .*?type="text" .*?value=\"9\"/) }
      it { should match(/input .*?name="crud_test_model\[human\]" .*?type="checkbox"/) }
      it { should match(/button .*?type="submit">Speichern<\/button>/) }
    end
   
    context "for new entry" do
      let(:entry) { CrudTestModel.new }
      
      it { should match(/form .*?action="\/crud_test_models" .?class="special form-horizontal" .*?method="post"/) }
      it { should match(/input .*?name="crud_test_model\[name\]" .*?type="text"/) }
      it { should_not match(/input .*?name="crud_test_model\[name\]" .*?type="text" .*?value=/) }
      it { should match(/select .*?name="crud_test_model\[birthdate\(1i\)\]"/) }
      it { should match(/input .*?name="crud_test_model\[children\]" .*?type="text"/) }
      it { should_not match(/input .*?name="crud_test_model\[children\]" .*?type="text" .*?value=/) }
      it { should match(/button .*?type="submit">Speichern<\/button>/) }
    end
    
    context "for invalid entry" do
      let(:entry) do
        e = crud_test_models(:AAAAA)
        e.name = nil
        e.valid?
        e 
      end
      
      it { should match(/div[^>]* id='error_explanation'/) }
      it { should match(/div class="control-group error"\>.*?\<input .*?name="crud_test_model\[name\]" .*?type="text"/) }
      it { should match(/input .*?name="_method" .*?type="hidden" .*?value="put"/) }
    end
  end
  
end
