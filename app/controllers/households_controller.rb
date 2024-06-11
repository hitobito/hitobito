# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class HouseholdsController < ApplicationController
  include DryCrud::InstanceVariables
  prepend Nestable

  self.nesting = [Group, Person]
  alias person parent
  before_action :entry
  helper_method :entry, :person

  def show
    redirect_to edit_group_person_household_path
  end

  def edit
    assign_and_validate if params.key?(:member_ids)
  end

  def update
    assign_and_validate if params.key?(:member_ids)

    if entry.save
      action = entry.members.empty? ? :destroy : action_name
      redirect_to parents, notice: success_message(action: action)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if entry.valid? && entry.destroy
      redirect_to parents, notice: success_message
    else
      render :edit
    end
  end

  private

  def assign_and_validate
    people.each { |person| entry.add(person) }
    (entry.people - people).each { |person| entry.remove(person) }
    entry.valid?
  end

  def success_message(action: action_name)
    t("crud.#{action}.flash.success", model: Household.model_name.human)
  end

  def people
    @people ||= Households::MembersQuery.new(current_user, person.id, Person)
                                        .scope.where(id: params[:member_ids])
  end

  def entry
    @entry ||= parent.household.tap do
      authorize!(:create_households, Person)
    end
  end
end
