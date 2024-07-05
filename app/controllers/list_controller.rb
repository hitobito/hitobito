#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Abstract controller providing a basic list action.
# This action lists all entries of a certain model and provides functionality to
# search and sort this list.
# Furthermore, it remembers the last search and sort parameters. When the action
# is called with a param returning=true, these parameters are reused to present
# the user the same list as he left it.
class ListController < ApplicationController
  # customized cancan code to authorize with #model_class
  authorize_resource except: :index
  before_action :authorize_class, only: :index

  helper_method :model_class, :models_label, :entries, :path_args

  delegate :model_class, :models_label, to: "self.class"

  respond_to :html
  include DryCrud::RenderCallbacks

  define_render_callbacks :index

  ##############  ACTIONS  ############################################

  # List all entries of this model.
  #   GET /entries
  #   GET /entries.json
  def index(&block)
    respond_with(entries, &block)
  end

  private

  # Helper method to access the entries to be displayed in the
  # current index page in an uniform way.
  def entries
    model_ivar_get(true) || model_ivar_set(list_entries)
  end

  # The base relation used to filter the entries.
  # This method may be adapted as long it returns an ActiveRecord::Relation.
  def list_entries
    model_scope
  end

  # The scope where model entries will be listed and created.
  # This is mainly used for nested models to provide the
  # required context.
  def model_scope
    model_class.all
  end

  # The path arguments to link to the given entry.
  # If the controller is nested, this provides the required context.
  def path_args(last)
    last
  end

  def authorize_class
    authorize!(action_name.to_sym, model_class)
  end

  class << self
    # The ActiveRecord class of the model.
    def model_class
      @model_class ||= controller_name.classify.constantize
    end

    # A human readable plural name of the model.
    def models_label(plural = true)
      opts = {count: (plural ? 3 : 1)}
      opts[:default] = model_class.model_name.human.titleize
      opts[:default] = opts[:default].pluralize if plural

      model_class.model_name.human(opts)
    end
  end

  include DryCrud::InstanceVariables
  include Searchable
  include Sortable
  include Rememberable
  prepend Nestable
end
