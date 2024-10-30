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
      get :index, params: {sort: :roles, sort_dir: :desc}
      expect(assigns(:entries)[0]).to eq bottom_member
    end

    it "has bottom member first" do
      get :index, params: {sort: :roles, sort_dir: :asc}
      expect(assigns(:entries)[0]).to eq top_leader
    end
  end
end
