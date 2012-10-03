require 'spec_helper'

describe StandardHelper do
  
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
      subject { labeled('label') { 'value' } }
      
      it { should be_html_safe }
      #its(:squish) { should == '<div class="labeled"> <label>label</label> <div class="value">value</div> </div>'.gsub('"', "'") }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>value</dd>'.gsub('"', "'") }
    end
    
    context "with empty value" do
      subject { labeled('label') { '' } }
      
      it { should be_html_safe }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>'.gsub('"', "'")+StandardHelper::EMPTY_STRING+'</dd>' }
    end
   
    context "with unsafe value" do
      subject { labeled('label') { 'value <unsafe>' } }
      
      it { should be_html_safe }
      its(:squish) { should == '<dt class="muted">label</dt> <dd>value &lt;unsafe&gt;</dd>'.gsub('"', "'") }
    end
  end
  
  describe "#labeled_attr" do
    subject { labeled_attr('foo', :size) }
    
    it { should be_html_safe }
    its(:squish) {  should == '<dt class="muted">Size</dt> <dd>3 chars</dd>'.gsub('"', "'") }
  end
  
  describe "#f" do

    context "Fixnums" do
      it "should print small values unchanged" do
        f(10).should == '10'
      end
      
      it "should print large values with delimiters" do
        f(10000000).should == "10'000'000"
      end
    end
    
    context "Floats" do
      it "should add two digits" do
        f(1.0).should == '1.00'
      end
      
      it "should truncate to two digits" do
        f(3.14159).should == '3.14'
      end
      
      it "should add delimiters" do
        f(12345.6789).should == "12'345.68"
      end
    end
    
    context "Booleans" do
      it "true should print yes" do
        f(true).should == 'ja'
      end
      
      it "false should print no" do
        f(false).should == 'nein'
      end
    end
    
    context "nil" do
      it "should print an empty string" do
        f(nil).should == StandardHelper::EMPTY_STRING
      end
    end
    
    context "Strings" do
      it "should print regular strings unchanged" do
        f('blah blah').should == 'blah blah'
      end
      
      it "should not be html safe" do
        f('<injection>').should_not be_html_safe
      end
    end
    
  end
  
  describe "#format_attr" do
    it "should use #f" do
      format_attr("12.342", :to_f).should == f(12.342)
    end
    
    it "should use object attr format method if it exists" do
      format_attr("abcd", :size).should == '4 chars'
    end
    
    it "should use general attr format method if it exists" do
      format_attr([1,2], :size).should == '2 items'
    end
    
    it "should format empty belongs_to" do
      format_attr(crud_test_models(:AAAAA), :companion).should == t(:'global.associations.no_entry')
    end
    
    it "should format existing belongs_to" do
      string = format_attr(crud_test_models(:BBBBB), :companion)
      string.should == "AAAAA"
    end
    
    it "should format existing has_many" do
      string = format_attr(crud_test_models(:CCCCC), :others)
      string.should be_html_safe
      string.should == "<ul><li>AAAAA</li><li>BBBBB</li></ul>"
    end
  end
  
  describe "#column_type" do
    let(:model) { crud_test_models(:AAAAA) }
    
    it "should recognize types" do
      column_type(model, :name).should == :string
      column_type(model, :children).should == :integer
      column_type(model, :companion_id).should == :integer
      column_type(model, :rating).should == :float
      column_type(model, :income).should == :decimal
      column_type(model, :birthdate).should == :date
      column_type(model, :gets_up_at).should == :time
      column_type(model, :last_seen).should == :datetime
      column_type(model, :human).should == :boolean
      column_type(model, :remarks).should == :text
      column_type(model, :companion).should be_nil
    end
  end
  
  describe "#format_type" do
    let(:model) { crud_test_models(:AAAAA) }
    
    it "should format integers" do
      model.children = 10000
      format_type(model, :children).should == "10'000"
    end
    
    it "should format floats" do
      format_type(model, :rating).should == '1.10'
    end
      
    it "should format decimals" do
      format_type(model, :income).should == "10'000'000.10"
    end

    it "should format dates" do
      format_type(model, :birthdate).should == '01.01.1910'
    end

    it "should format times" do
      format_type(model, :gets_up_at).should == '01:01'
    end

    it "should format datetimes" do
      format_type(model, :last_seen).should == '01.01.2010 11:21'
    end

    it "should format texts" do
      string = format_type(model, :remarks)
      string.should be_html_safe
      string.should == "<p>AAAAA BBBBB CCCCC\n<br />AAAAA BBBBB CCCCC\n</p>"
    end

    it "should escape texts" do
      model.remarks = "<unsecure>bla"
      string = format_type(model, :remarks)
      string.should be_html_safe
      string.should == "<p>&lt;unsecure&gt;bla</p>"
    end
    
    it "should format empty texts" do
      model.remarks = "   "
      string = format_type(model, :remarks)
      string.should be_html_safe
      string.should == StandardHelper::EMPTY_STRING
    end
  end
  
  describe "#content_tag_nested" do
    
    it "should escape safe content" do
      html = content_tag_nested(:div, ['a', 'b']) { |e| content_tag(:span, e) }
      html.should be_html_safe
      html.should == "<div><span>a</span><span>b</span></div>"
    end
    
    it "should escape unsafe content" do
      html = content_tag_nested(:div, ['a', 'b']) { |e| "<#{e}>" }
      html.should == "<div>&lt;a&gt;&lt;b&gt;</div>"
    end
    
    it "should simply join without block" do
      html = content_tag_nested(:div, ['a', 'b'])
      html.should == "<div>ab</div>"
    end
  end
  
  describe "#safe_join" do
    it "should works as super without block" do
      html = safe_join(['<a>', '<b>'.html_safe])
      html.should == "&lt;a&gt;<b>"
    end
    
    it "should collect contents for array" do
      html = safe_join(['a', 'b']) { |e| content_tag(:span, e) }
      html.should == "<span>a</span><span>b</span>"
    end
  end
  
  describe "#captionize" do
    it "should handle symbols" do
      captionize(:camel_case).should == 'Camel Case'
    end
    
    it "should render all upper case" do
      captionize('all upper case').should == 'All Upper Case'
    end
    
    it "should render human attribute name" do
      captionize(:gets_up_at, CrudTestModel).should == 'Gets up at'
    end
  end
  
  describe "#table" do
    context "with empty data" do
      subject { table([]) }
      
      it { should be_html_safe }
      
      it "should handle empty data" do
        should match(/Keine Eintr/)
      end
    end
    
    context "with data" do
      subject { table(['foo', 'bar'], :size) {|t| t.attrs :upcase } }
       
      it { should be_html_safe }

      it "should render table" do
        should match(/^\<table.*\<\/table\>$/)
      end
      
      it "should contain attrs" do
        should match(/<th>Size<\/th>/)
      end
      
      it "should contain block" do
        should match(/<th>Upcase<\/th>/)
      end
    end
  end
  
  describe "#standard_form" do
    subject do
      with_test_routing do
        capture { standard_form(entry, :html => {:class => 'special'}) {|f| } }
      end
    end
    
    let(:entry) { crud_test_models(:AAAAA) }
      
    it { should match(/form .*?action="\/crud_test_models\/#{entry.id}" .?class="special form-horizontal" .*?method="post"/) }
  
  end
  
  describe "#translate_inheritable" do
    before { @controller = CrudTestModelsController.new }
    
    before { I18n.backend.store_translations :de, :global => { :test_key => 'global' } }
    subject { ti(:test_key) }
    
    it { should == 'global' }
    
    context "with list key" do
      before { I18n.backend.store_translations :de, :list => { :global => {:test_key => 'list global'} } }
      it { should == 'list global' }
      
      context "and list action key" do
        before { I18n.backend.store_translations :de, :list => { :index => {:test_key => 'list index'} } }
        it { should == 'list index' }
              
        context "and crud global key" do
          before { I18n.backend.store_translations :de, :crud => {  :global => {:test_key => 'crud global'} } }
          it { should == 'crud global' }
          
          context "and crud action key" do
            before { I18n.backend.store_translations :de, :crud => {  :index => {:test_key => 'crud index'} } }
            it { should == 'crud index' }
          
            context "and controller global key" do
              before { I18n.backend.store_translations :de, :crud_test_models => {  :global => {:test_key => 'test global'} } }
              it { should == 'test global' }
              
              context "and controller action key" do
                before { I18n.backend.store_translations :de, :crud_test_models => {  :index => {:test_key => 'test index'} } }
                it { should == 'test index' }
              end
            end
          end
        end
      end
    end
  end
  
  describe "#translate_association" do
    let(:assoc) { CrudTestModel.reflect_on_association(:companion) }
    subject { ta(:test_key, assoc)}
    
    before { I18n.backend.store_translations :de, :global => { :associations => {:test_key => 'global'} } }
    it { should == 'global' }
    
    context "with model key" do
      before do
        I18n.backend.store_translations :de, 
            :activerecord => { 
              :associations => { 
                :crud_test_model => {
                  :test_key => 'model'} } }
      end
      
      it { should == 'model' }
      
      context "and assoc key" do
        before do
          I18n.backend.store_translations :de, 
             :activerecord => { 
               :associations => { 
                 :models => {
                   :crud_test_model => { 
                     :companion => {
                       :test_key => 'companion'} } } } }
        end
       
        it { should == 'companion' }
        it "should use global without assoc" do
          ta(:test_key).should == 'global'
        end
      end
    end
  end
end
