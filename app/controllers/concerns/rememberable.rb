# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Remembers certain params of the index action in order to return
# to the same list after an entry was viewed or edited.
# If the index is called with a param :returning, the remembered params
# will be re-used.
# Extracted into an own module for convenience.
module Rememberable
  # Adds the :remember_params class attribute and a before filter to the index action.
  def self.included(controller)
    # Define a list of param keys that should be remembered for the list action.
    controller.class_attribute :remember_params
    controller.remember_params = [:q, :sort, :sort_dir, :page]

    controller.prepend_before_action :handle_remember_params, only: [:index]
  end

  private

  # Store and restore the corresponding params.
  def handle_remember_params
    remembered = remembered_params

    restore_params_on_return(remembered)
    store_current_params(remembered)
    clear_void_params(remembered)
  end

  def restore_params_on_return(remembered)
    if params[:returning]
      remember_params.each { |p| params[p] ||= remembered[p] }
    end
  end

  def store_current_params(remembered)
    remember_params.each do |p|
      remembered[p] = params[p].presence
      remembered.delete(p) if remembered[p].nil?
    end
  end

  def clear_void_params(remembered)
    session[:list_params].delete(remember_key) if remembered.blank?
  end

  # Get the params stored in the session.
  def remembered_params
    session[:list_params] ||= {}
    session[:list_params][remember_key] ||= {}
  end

  # Params are stored by request path to play nice when a controller
  # is used in different routes.
  # Does not consider the format though
  def remember_key
    @remember_key ||= request.path[/(.+?)(\.[^\/\.]+)?$/, 1]
  end
end
