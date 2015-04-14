# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

# Tests all actions of the CrudController based on a dummy model
# (CrudTestModel). This is useful to test the general behavior
# of CrudController.

describe CrudTestModelsController, type: :controller do

  include CrudTestHelper

  before(:all) do
    reset_db
    setup_db
    create_test_data
  end

  after(:all) { reset_db }

  before { special_routing }

  # it_should_behave_like 'crud controller'
  include_examples 'crud controller'

  let(:test_entry) { crud_test_models(:AAAAA) }
  let(:test_entry_attrs) do
    { name: 'foo',
      children: 42,
      companion_id: 3,
      rating: 8.5,
      income: 2.42,
      birthdate: '31-12-1999'.to_date,
      human: true,
      remarks: "some custom\n\tremarks" }
  end


  describe 'setup' do
    it 'model count should be correct' do
      expect(CrudTestModel.count).to eq(6)
    end

    it 'should have models_label' do
      expect(controller.models_label).to eq('Crud Test Models')
    end

    it 'should have models_label singular' do
      expect(controller.models_label(false)).to eq('Crud Test Model')
    end

=begin
    it "should route index" do
      { get: "/crud_test_models" }.should route_to(
        controller: "crud_test_models",
        action: "index"
      )
    end

    it "should route show" do
      { get: "/crud_test_models/1" }.should route_to(
        controller: "crud_test_models",
        action: "show",
        id: '1'
      )
    end
=end
  end

  describe_action(:get, :index) do
    context('.html', format: :html) do
      context 'plain', combine: 'ihpc' do
        it 'should contain all entries' do
          expect(entries.size).to eq(6)
        end

        it 'session should have empty list_params' do
          expect(session[:list_params]).to eq(Hash.new)
        end

        it 'should provide entries helper method' do
          is_expected.to render_template('index')
          expect(entries).to eq(controller.send(:entries))
        end
      end

      context 'search' do
        let(:params) { { q: search_value } }

        it 'entries should only contain test_entry' do
          expect(entries).to eq([test_entry])
        end

        it 'session should have query list param' do
          expect(session[:list_params]['/crud_test_models']).to eq({ q: 'AAAA' })
        end

        context 'with custom options', combine: 'ihsc' do
          let(:params) { { q: 'DDD', filter: true } }

          it_should_respond

          it 'entries should have one item' do
            expect(entries).to eq([CrudTestModel.find_by_name('BBBBB')])
          end

          it 'session should have query list param' do
            expect(session[:list_params]['/crud_test_models']).to eq({ q: 'DDD' })
          end
        end
      end

      context 'sort' do
        context 'for given column', combine: 'ihsoc' do
          let(:params) { { sort: 'children', sort_dir: 'asc' } }

          it_should_respond

          it 'entries should be in correct order' do
            expect(entries).to eq(CrudTestModel.all.sort_by(&:children))
          end

          it 'session should have sort list param' do
            expect(session[:list_params]['/crud_test_models']).to eq({ sort: 'children', sort_dir: 'asc' })
          end
        end

        context 'for virtual column', combine: 'ihsov' do
          let(:params) { { sort: 'chatty', sort_dir: 'desc' } }

          it_should_respond

          it 'entries should be in correct order' do
            names = entries.collect(&:name)
            assert names.index('BBBBB') < names.index('AAAAA')
            assert names.index('BBBBB') < names.index('DDDDD')
            assert names.index('EEEEE') < names.index('AAAAA')
            assert names.index('EEEEE') < names.index('DDDDD')
            assert names.index('AAAAA') < names.index('CCCCC')
            assert names.index('DDDDD') < names.index('CCCCC')
          end

          it 'session should have sort list param' do
            expect(session[:list_params]['/crud_test_models']).to eq({ sort: 'chatty', sort_dir: 'desc' })
          end
        end

        context 'with search', combine: 'ihsose' do
          let(:params) { { q: 'DDD', sort: 'chatty', sort_dir: 'asc' } }

          it_should_respond

          it 'entries should be in correct order' do
            expect(entries.collect(&:name)).to eq(%w(CCCCC DDDDD BBBBB))
          end

          it 'session should have sort list param' do
            expect(session[:list_params]['/crud_test_models']).to eq({ q: 'DDD', sort: 'chatty', sort_dir: 'asc' })
          end
        end
      end

      context 'with custom options', combine: 'ihsoco' do
        let(:params) { { filter: true } }

        it_should_respond

        context 'entries' do
          subject { entries }
          it 'has 2 items' do
            expect(subject.size).to eq(2)
          end
          it { expect(entries.collect(&:id)).to eq(entries.sort_by(&:children).collect(&:id).reverse) }
        end
      end

      context 'returning', perform_request: false do
        before do
          session[:list_params] = {}
          session[:list_params]['/crud_test_models'] = { q: 'DDD', sort: 'chatty', sort_dir: 'desc' }
          sign_in(user)
          get :index, returning: true
        end

        it_should_respond

        it 'entries should be in correct order' do
          expect(entries.collect(&:name)).to eq(%w(BBBBB DDDDD CCCCC))
        end

        it 'params should be set' do
          expect(controller.params[:q]).to eq('DDD')
          expect(controller.params[:sort]).to eq('chatty')
          expect(controller.params[:sort_dir]).to eq('desc')
        end
      end
    end

    context '.js', format: :js, combine: 'ijs' do
      it_should_respond
      it_should_assign_entries
      its(:body) { should == 'index js' }
    end
  end

  describe_action :get, :new do
    it 'should assign companions' do
      expect(assigns(:companions)).to be_present
    end

    it 'should have called two render callbacks' do
      expect(controller.called_callbacks).to eq([:before_render_new, :before_render_form])
    end

    context 'with before_render callback redirect', perform_request: false do
      before do
        controller.should_redirect = true
        perform_request
      end

      it { is_expected.to redirect_to(crud_test_models_path) }

      it 'should not set companions' do
        expect(assigns(:companions)).to be_nil
      end
    end
  end

  describe_action :post, :create do
    let(:params) { { model_identifier => test_entry_attrs } }

    it 'should have called the correct callbacks' do
      expect(controller.called_callbacks).to eq([:before_create, :before_save, :after_save, :after_create])
    end

    context 'with before callback' do
      let(:params) { { crud_test_model: { name: 'illegal', children: 2 } } }
      it 'should not create entry', perform_request: false do
        expect { perform_request }.to change { CrudTestModel.count }.by(0)
      end

      context 'regular', combine: 'chreg' do
        it_should_respond
        it_should_render('new')
        it_should_persist_entry(false)
        it_should_have_flash(:alert)

        it 'should set entry name' do
          expect(entry.name).to eq('illegal')
        end

        it 'should assign companions' do
          expect(assigns(:companions)).to be_present
        end

        it 'should have called the correct callbacks' do
          expect(controller.called_callbacks).to eq([:before_render_new, :before_render_form])
        end
      end

      context 'redirect', perform_request: false do
        before { controller.should_redirect = true }

        it 'should not create entry' do
          expect { perform_request }.to change { CrudTestModel.count }.by(0)
        end

        it { perform_request; is_expected.to redirect_to(crud_test_models_path) }

        it 'should have called no callbacks' do
          perform_request
          expect(controller.called_callbacks).to be_nil
        end
      end
    end

    context 'with invalid params' do
      let(:params) { { crud_test_model: { children: 2 } } }

      context '.html' do
        it 'should not create entry', perform_request: false do
          expect { perform_request }.to change { CrudTestModel.count }.by(0)
        end

        context 'regular', combine: 'chivreg' do
          it_should_respond
          it_should_render('new')
          it_should_persist_entry(false)
          it_should_not_have_flash(:notice)
          it_should_not_have_flash(:alert)

          it 'should assign companions' do
            expect(assigns(:companions)).to be_present
          end

          it 'should have called the correct callbacks' do
            expect(controller.called_callbacks).to eq([:before_create, :before_save, :before_render_new, :before_render_form])
          end
        end
      end

      context '.json', format: :json do
        it 'should not create entry', perform_request: false do
          expect { perform_request }.to change { CrudTestModel.count }.by(0)
        end

        context 'regular', combine: 'cjreg' do
          it_should_respond(422)
          it_should_persist_entry(false)
          it_should_not_have_flash(:notice)
          it_should_not_have_flash(:alert)

          it 'should not assign companions' do
            expect(assigns(:companions)).to be_nil
          end

          it 'should have called the correct callbacks' do
            expect(controller.called_callbacks).to eq([:before_create, :before_save])
          end

          its(:body) { is_expected.to match(/errors/) }
        end
      end
    end

  end

  describe_action :get, :edit, id: true do
    it 'should have called the correct callbacks' do
      expect(controller.called_callbacks).to eq([:before_render_edit, :before_render_form])
    end
  end

  describe_action :put, :update, id: true do
    let(:params) { { model_identifier => test_entry_attrs } }

    it 'should have called the correct callbacks' do
      expect(controller.called_callbacks).to eq([:before_update, :before_save, :after_save, :after_update])
    end

    context 'with invalid params' do
      let(:params) { { crud_test_model: { rating: 20 } } }

      context '.html', combine: 'uherg' do
        it_should_respond
        it_should_render('edit')
        it_should_not_have_flash(:notice)

        it 'should change entry' do
          expect(entry).to be_changed
        end

        it 'should set entry rating' do
          expect(entry.rating).to eq(20)
        end

        it 'should have called the correct callbacks' do
          expect(controller.called_callbacks).to eq([:before_update, :before_save, :before_render_edit, :before_render_form])
        end
      end

      context '.json', format: :json, combine: 'ujreg' do
        it_should_respond(422)
        it_should_not_have_flash(:notice)

        it 'should have called the correct callbacks' do
          expect(controller.called_callbacks).to eq([:before_update, :before_save])
        end

        its(:body) { is_expected.to match(/errors/) }
      end
    end

  end

  describe_action :delete, :destroy, id: true do
    it 'should have called the correct callbacks' do
      expect(controller.called_callbacks).to eq([:before_destroy, :after_destroy])
    end

    context 'with failure' do
      let(:test_entry) { crud_test_models(:BBBBB) }
      context '.html' do
        it 'should not delete entry from database', perform_request: false do
          expect { perform_request }.to change { CrudTestModel.count }.by(0)
        end

        it 'should redirect to referer', perform_request: false do
          ref = @request.env['HTTP_REFERER'] = crud_test_model_url(test_entry)
          perform_request
          is_expected.to redirect_to(ref)
        end

        it_should_have_flash(:alert, /companion/)
        it_should_not_have_flash(:notice)
      end

      context '.json', format: :json, combine: 'djreg' do
        it_should_respond(422)
        it_should_not_have_flash(:notice)
        its(:body) { is_expected.to match(/errors/) }
      end

      context 'callback', perform_request: false do
        before do
          test_entry.update_attribute :name, 'illegal'
        end

        it 'should not delete entry from database' do
          expect { perform_request }.to change { CrudTestModel.count }.by(0)
        end

        it 'should redirect to index' do
          perform_request
          is_expected.to redirect_to(crud_test_models_path(returning: true))
        end

        it 'should have flash alert' do
          perform_request
          expect(flash[:alert]).to match(/illegal name/)
        end
      end
    end

  end


end
