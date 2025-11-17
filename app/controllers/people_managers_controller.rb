# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class PeopleManagersController < ApplicationController
  before_action :authorize_action, except: [:index]
  before_action :authorize_class, only: :index
  helper_method :entry, :person

  class_attribute :assoc

  def index
  end

  def new
  end

  def create
    assign_attributes

    success = ActiveRecord::Base.transaction do
      if entry.save && entry.managed.valid? && entry.manager.valid?
        yield entry if block_given?
        true
      else
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to redirect_to_path
    else
      render :new, status: :unprocessable_content, layout: false
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      find_entry.tap do |entry|
        entry.destroy!
        yield entry if block_given?
      end
    end
    redirect_to redirect_to_path
  end

  private

  def authorize_action
    kind = assoc.to_s.split("_").last.singularize
    action_to_authorize = :"#{action_name}_#{kind}"

    authorize!(action_to_authorize, entry)
  rescue CanCan::AccessDenied => e
    entry.errors.add(:base, e.message)
    render :new, status: :unprocessable_content
  end

  def authorize_class
    authorize!(:index, PeopleManager)
  end

  def assign_attributes
    entry.attributes = model_params
  end

  def entry
    @entry ||= person.send(assoc).build
  end

  def find_entry
    person.send(assoc).find(params[:id])
  end

  def person
    @person ||= Person
      .accessible_by(current_ability)
      .find(params[:person_id])
  end
end
