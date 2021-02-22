#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# require 'support/crud_controller_test_helper'

RSpec.configure do |c|
  c.before failing: true do
    allow_any_instance_of(model_class).to receive(:save).and_return(false)
    allow_any_instance_of(model_class).to receive(:destroy).and_return(false)
  end

  # currently, no json for hitobito
  c.filter_run_excluding format: :json

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  c.infer_spec_type_from_file_location!
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

  let(:user) { people(:top_leader) }
  let(:model_class) { controller.send(:model_class) }
  let(:model_identifier) { controller.model_identifier }
  let(:test_params) { scope_params }
  let(:entry) { assigns(controller.send(:ivar_name, model_class)) }
  let(:entries) { assigns(controller.send(:ivar_name, model_class).pluralize) }
  let(:sort_column) { model_class.column_names.first }

  let(:search_value) do
    field = controller.search_columns.first
    val = test_entry[field].to_s
    val[0..((val.size + 1) / 2)]
  end

  before do |example|
    m = example.metadata
    perform_combined_request if m[:perform_request] != false && m[:action] && m[:method]
  end

  describe_action :get, :index, unless: skip?(options, "index") do
    context ".html", format: :html, unless: skip?(options, %w[index html]) do
      context "plain", unless: skip?(options, %w[index html plain]), combine: "ihp" do
        it_should_respond
        it_should_assign_entries
        it_should_render
      end

      context "search", if: described_class.search_columns.present?, unless: skip?(options, %w[index html search]), combine: "ihse" do
        let(:params) { {q: search_value} }

        it_should_respond
        context "entries" do
          subject { entries }

          it { is_expected.to include(test_entry) }
        end
      end

      context "sort", unless: skip?(options, %w[index html sort]) do
        context "ascending", unless: skip?(options, %w[index html sort ascending]), combine: "ihsa" do
          let(:params) { {sort: sort_column, sort_dir: "asc"} }

          it_should_respond
          it "should have sorted entries" do
            sorted = entries.sort_by(&sort_column.to_sym).collect(&:id)
            expect(entries.collect(&:id)).to eq(sorted)
          end
        end

        context "descending", unless: skip?(options, %w[index html sort descending]), combine: "ihsd" do
          let(:params) { {sort: sort_column, sort_dir: "desc"} }

          it_should_respond
          it "should have sorted entries" do
            sorted = entries.sort_by(&sort_column.to_sym)
            expect(entries.to_a).to eq(sorted.reverse)
          end
        end
      end
    end

    context ".json", format: :json, unless: skip?(options, %w[index json]), combine: "ij" do
      it_should_respond
      it_should_assign_entries
      its(:body) { is_expected.to start_with("[{") }
    end
  end

  describe_action :get, :show, id: true, unless: skip?(options, "show") do
    context ".html", format: :html, unless: skip?(options, %w[show html]) do
      context "plain", unless: skip?(options, %w[show html plain]), combine: "sh" do
        it_should_respond
        it_should_assign_entry
        it_should_render
      end

      context "with non-existing id", unless: skip?(options, "show", "html", "with non-existing id") do
        let(:params) { {id: 9999} }

        it "should raise RecordNotFound", perform_request: false do
          expect { perform_request }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context ".json", format: :json, unless: skip?(options, %w[show json]), combine: "sj" do
      it_should_respond
      it_should_assign_entry
      its(:body) { is_expected.to start_with("{") }
    end
  end

  describe_action :get, :new, unless: skip?(options, %w[new]) do
    context "plain", unless: skip?(options, %w[new plain]), combine: "np" do
      it_should_respond
      it_should_render
      it_should_persist_entry(false)
    end

    context "with params", unless: skip?(options, "new", "with params") do
      let(:params) { {model_identifier => test_attrs} }

      it_should_set_attrs
    end
  end

  describe_action :post, :create, unless: skip?(options, %w[create]) do
    let(:params) { {model_identifier => test_attrs} }

    it "should add entry to database", perform_request: false do
      expect { perform_request }.to change { model_class.count }.by(1)
    end

    context "html", format: :html, unless: skip?(options, %w[create html]) do
      context "with valid params", unless: skip?(options, %w[create html valid]), combine: "chv" do
        it_should_redirect_to_show
        it_should_set_attrs
        it_should_persist_entry
        it_should_have_flash(:notice)
      end

      context "with invalid params", failing: true, unless: skip?(options, %w[create html invalid]), combine: "chi" do
        it_should_render("new")
        it_should_persist_entry(false)
        it_should_set_attrs
        it_should_not_have_flash(:notice)
      end
    end

    context "json", format: :json, unless: skip?(options, %w[create json]) do
      context "with valid params", unless: skip?(options, %w[create json valid]), combine: "cjv" do
        it_should_respond(201)
        it_should_set_attrs
        its(:body) { is_expected.to start_with("{") }
        it_should_persist_entry
      end

      context "with invalid params", failing: true, unless: skip?(options, %w[create json invalid]), combine: "cji" do
        it_should_respond(422)
        it_should_set_attrs
        its(:body) { is_expected.to match(/"errors":\{/) }
        it_should_persist_entry(false)
      end
    end
  end

  describe_action :get, :edit, id: true, unless: skip?(options, %w[edit]), combine: "edit" do
    it_should_respond
    it_should_render
    it_should_assign_entry
  end

  describe_action :put, :update, id: true, unless: skip?(options, %w[update]) do
    let(:params) { {model_identifier => test_attrs} }

    it "should update entry in database", perform_request: false do
      expect { perform_request }.to change { model_class.count }.by(0)
    end

    context ".html", format: :html, unless: skip?(options, %w[update html]) do
      context "with valid params", unless: skip?(options, %w[update html valid]), combine: "uhv" do
        it_should_set_attrs
        it_should_redirect_to_show
        it_should_persist_entry
        it_should_have_flash(:notice)
      end

      context "with invalid params", failing: true, unless: skip?(options, %w[update html invalid]), combine: "uhi" do
        it_should_render("edit")
        it_should_set_attrs
        it_should_not_have_flash(:notice)
      end
    end

    context ".json", format: :json, unless: skip?(options, %w[udpate json]) do
      context "with valid params", unless: skip?(options, %w[udpate json valid]), combine: "ujv" do
        it_should_respond(204)
        it_should_set_attrs
        its(:body) { is_expected.to match(/s*/) }
        it_should_persist_entry
      end

      context "with invalid params", failing: true, unless: skip?(options, %w[update json invalid]), combine: "uji" do
        it_should_respond(422)
        it_should_set_attrs
        its(:body) { is_expected.to match(/"errors":\{/) }
      end
    end
  end

  describe_action :delete, :destroy, id: true, unless: skip?(options, %w[destroy]) do
    it "should remove entry from database", perform_request: false do
      expect { perform_request }.to change { model_class.count }.by(-1)
    end

    context ".html", format: :html, unless: skip?(options, %w[destroy html]) do
      context "successfull", combine: "dhs" do
        it_should_redirect_to_index
        it_should_have_flash(:notice)
      end

      context "with failure", failing: true, unless: skip?(options, %w[destroy html invalid]), combine: "dhf" do
        it_should_redirect_to_index
        it_should_have_flash(:alert)
      end
    end

    context ".json", format: :json, unless: skip?(options, %w[destroy json]) do
      context "successfull", combine: "djs" do
        it_should_respond(204)
        its(:body) { is_expected.to match(/s*/) }
      end

      context "with failure", failing: true, combine: "djf" do
        it_should_respond(422)
        its(:body) { is_expected.to match(/"errors":\{/) }
      end
    end
  end
end
