#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Sortable, type: :controller do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  controller(ActionController::Base) do
    class_attribute :model_class, default: Person

    def index
      @entries = list_entries.tap do |scope|
        # puts scope.to_sql
      end
      head :ok
    end

    def list_entries = model_class.all.distinct
    include Sortable
  end

  after do
    expect_no_duplicated_entries # check that no entry duplicates after sorting
  end

  describe "basic sorting on model attribute" do
    it "has top leader first" do
      get :index, params: {sort: :first_name, sort_dir: :desc}
      expect(assigns(:entries)[0]).to eq top_leader
    end

    it "has bottom member first" do
      get :index, params: {sort: :first_name, sort_dir: :asc}
      expect(assigns(:entries)[0]).to eq bottom_member
    end
  end

  describe "complex sorting with custom join and order with case statement" do
    before do
      controller.class.sort_mappings = {
        roles: {
          joins: [:roles, "INNER JOIN role_type_orders ON roles.type = role_type_orders.name"],
          order: ["order_weight", Person.order_by_name_statement]
        }
      }
    end

    it "has top leader first" do
      get :index, params: {sort: :roles, sort_dir: :asc}
      expect(assigns(:entries)[0]).to eq top_leader
    end

    it "has bottom member first" do
      get :index, params: {sort: :roles, sort_dir: :desc}
      expect(assigns(:entries)[0]).to eq bottom_member
    end
  end

  describe "complex sorting on already grouped query" do
    before do
      controller.class.sort_mappings = {
        roles: {
          joins: [:roles, "INNER JOIN role_type_orders ON roles.type = role_type_orders.name"],
          order: ["role_type_orders.order_weight"]
        }
      }

      controller.singleton_class.class_eval do
        define_method(:list_entries) do
          sort_by_sort_expression(Person.select("MAX(people.id) AS id").group(:id)) # group query before passing it into sort_by_sort_expression
        end
      end
    end

    it "has top leader first" do
      get :index, params: {sort: :roles, sort_dir: :asc}
      expect(assigns(:entries)[0]).to eq top_leader
    end

    it "has bottom member first" do
      get :index, params: {sort: :roles, sort_dir: :desc}
      expect(assigns(:entries)[0]).to eq bottom_member
    end
  end

  describe "complex sorting on already distinct on subquery" do
    before do
      controller.class.sort_mappings = {
        name: {
          joins: [:translations],
          order: ["event_translations.name"]
        }
      }

      controller.singleton_class.class_eval do
        define_method(:list_entries) do
          # Event list includes translations and creates a distinct on subquery to prevent doubling records
          sort_by_sort_expression(Event.list)
        end
      end
    end

    it "has top course first" do
      get :index, params: {sort: :name, sort_dir: :asc}
      expect(assigns(:entries)[0]).to eq events(:top_course)
    end

    it "has top event first" do
      get :index, params: {sort: :name, sort_dir: :desc}
      expect(assigns(:entries)[0]).to eq events(:top_event)
    end
  end

  def expect_no_duplicated_entries
    ids = assigns(:entries).map(&:id)
    duplicates = ids.select { |id| ids.count(id) > 1 }.uniq
    expect(duplicates).to be_empty, "Duplicated entries in response: #{duplicates.join(", ")}"
  end
end
