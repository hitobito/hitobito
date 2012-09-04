#require 'support/crud_controller_test_helper'

RSpec.configure do |c|
  c.before :failing => true do
    model_class.any_instance.stub(:save).and_return(false)
    model_class.any_instance.stub(:destroy).and_return(false)
  end
end

# A set of examples to include into the tests for your crud controller subclasses.
# Simply #let :test_entry and :test_entry_attrs to test the basic
# crud functionality. 
# If single examples do not match with you implementation, you may skip
# them by passing a skip parameter with context arrays:
#   include_examples 'crud controller', :skip => [%w(index html sort) %w(destroy json)]
shared_examples "crud controller" do |options|

  include CrudControllerTestHelper

  render_views

  subject { response }
  
  let(:model_class)      { controller.send(:model_class) }
  let(:model_identifier) { controller.model_identifier }
  let(:test_params)      { scope_params }
  let(:entry)            { assigns(model_identifier) }
  let(:entries)          { assigns(model_identifier.to_s.pluralize.to_sym) }
  let(:sort_column)      { model_class.column_names.first }
  let(:search_value) do
    field = controller.search_columns.first
    val = test_entry[field].to_s
    val[0..((val.size + 1)/ 2)]
  end

  before do
    m = example.metadata
    perform_request if m[:perform_request] != false && m[:action] && m[:method]
  end

  describe_action :get, :index, :unless => skip?(options, 'index') do
    
    context ".html", :format => :html, :unless => skip?(options, %w(index html)) do
    
      context 'plain', :unless => skip?(options, %w(index html plain)) do
        it_should_respond
        it_should_assign_entries
        it_should_render
      end
      
      context "search", :if => described_class.search_columns.present?, :unless => skip?(options, %w(index html search)) do
        let(:params) { {:q => search_value} }
        
        it_should_respond
        context "entries" do
          subject { entries }
          it { should include(test_entry) }
        end
      end
      
      context "sort", :unless => skip?(options, %w(index html sort)) do
        context "ascending", :unless => skip?(options, %w(index html sort ascending)) do
          let(:params) { {:sort => sort_column, :sort_dir => 'asc'} } 
          
          it_should_respond
          it "should have sorted entries" do
            sorted = entries.sort_by(&(sort_column.to_sym))
            entries.should == sorted
          end
        end
        
        context "descending", :unless => skip?(options, %w(index html sort descending)) do
          let(:params) { {:sort => sort_column, :sort_dir => 'desc'} } 
      
          it_should_respond
          it "should have sorted entries" do
            sorted = entries.sort_by(&(sort_column.to_sym))
            entries.should == sorted.reverse
          end
        end
      end
    end
    
    context ".json", :format => :json, :unless => skip?(options, %w(index json)) do
      it_should_respond
      it_should_assign_entries
      its(:body) { should start_with('[{') }
    end
    
  end
  
  describe_action :get, :show, :id => true, :unless => skip?(options, 'show') do

    context ".html", :format => :html, :unless => skip?(options, %w(show html)) do
      context "plain", :unless => skip?(options, %w(show html plain)) do
        it_should_respond
        it_should_assign_entry
        it_should_render
      end
      
      context "with non-existing id", :unless => skip?(options, 'show', 'html', 'with non-existing id') do
        let(:params) { {:id => 9999 } }
        
        it "should raise RecordNotFound", :perform_request => false do
          expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
    
    context ".json", :format => :json, :unless => skip?(options, %w(show json)) do
      it_should_respond
      it_should_assign_entry
      its(:body) { should start_with('{') }
    end
  end
  
  describe_action :get, :new, :unless => skip?(options, %w(new)) do
    context "plain", :unless => skip?(options, %w(index plain)) do
      it_should_respond
      it_should_render
      it_should_persist_entry(false)
    end
    
    context "with params", :unless => skip?(options, 'new', 'with params') do
      let(:params) { { model_identifier => test_entry_attrs } }
      it_should_set_attrs
    end
  end
  
  describe_action :post, :create, :unless => skip?(options, %w(create)) do
    let(:params) { { model_identifier => test_entry_attrs } }
    
    it "should add entry to database", :perform_request => false do
      expect { perform_request }.to change { model_class.count }.by(1)
    end
    
    context "html", :format => :html, :unless => skip?(options, %w(create html)) do
      context "with valid params", :unless => skip?(options, %w(create html valid)) do
        it_should_redirect_to_show
        it_should_set_attrs
        it_should_persist_entry
        it_should_have_flash(:notice)
      end
      
      context "with invalid params", :failing => true, :unless => skip?(options, %w(create html invalid)) do
        it_should_render('new')
        it_should_persist_entry(false)
        it_should_set_attrs
        it_should_not_have_flash(:notice)
      end
    end
    
    context "json", :format => :json, :unless => skip?(options, %w(create json)) do
      context "with valid params", :unless => skip?(options, %w(create json valid)) do
        it_should_respond(201)
        it_should_set_attrs
        its(:body) { should start_with('{') }
        it_should_persist_entry
      end
      
      context "with invalid params", :failing => true, :unless => skip?(options, %w(create json invalid)) do
        it_should_respond(422)
        it_should_set_attrs
        its(:body) { should match(/"errors":\{/) }
        it_should_persist_entry(false)
      end
    end
  end
  
  describe_action :get, :edit, :id => true, :unless => skip?(options, %w(edit)) do
    it_should_respond
    it_should_render
    it_should_assign_entry
  end
  
  describe_action :put, :update, :id => true, :unless => skip?(options, %w(update)) do
    let(:params) { {model_identifier => test_entry_attrs} }
    
    it "should update entry in database", :perform_request => false do
      expect { perform_request }.to change { model_class.count }.by(0)
    end
    
    context ".html", :format => :html, :unless => skip?(options, %w(update html)) do
      context "with valid params", :unless => skip?(options, %w(update html valid)) do
        it_should_set_attrs
        it_should_redirect_to_show
        it_should_persist_entry
        it_should_have_flash(:notice)
      end
      
      context "with invalid params", :failing => true, :unless => skip?(options, %w(update html invalid)) do
        it_should_render('edit')
        it_should_set_attrs
        it_should_not_have_flash(:notice)
      end
    end
    
    context ".json", :format => :json, :unless => skip?(options, %w(udpate json)) do
      context "with valid params", :unless => skip?(options, %w(udpate json valid)) do
        it_should_respond(204)
        it_should_set_attrs
        its(:body) { should match(/s*/) }
        it_should_persist_entry
      end
      
      context "with invalid params", :failing => true, :unless => skip?(options, %w(update json invalid)) do
        it_should_respond(422)
        it_should_set_attrs
        its(:body) { should match(/"errors":\{/) }
      end
    end
  end
  
  describe_action :delete, :destroy, :id => true, :unless => skip?(options, %w(destroy)) do
    
    it "should remove entry from database", :perform_request => false  do
      expect { perform_request }.to change { model_class.count }.by(-1)
    end
    
    context ".html", :format => :html, :unless => skip?(options, %w(destroy html)) do
      it_should_redirect_to_index
      it_should_have_flash(:notice)
      
      context "with failure", :failing => true do
        it_should_redirect_to_index
        it_should_have_flash(:alert)
      end
    end
    
    context ".json", :format => :json, :unless => skip?(options, %w(destroy json)) do
      it_should_respond(204)
      its(:body) { should match(/s*/) }
      
      context "with failure", :failing => true do
        it_should_respond(422)
        its(:body) { should match(/"errors":\{/) }
      end
    end
  end
  
end

