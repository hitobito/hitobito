# frozen_string_literal: true

#  Copyright (c) 2012-2026, Bund der Pfadfinderinnen und Pfadfinder e.V.. This file is part of
#  hitobito and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class PeopleManagerResource < ApplicationResource
  self.acceptable_scopes += %w[people]
  self.readable_class = JsonApi::PeopleManagerReadables

  attribute :manager_id, :integer
  attribute :managed_id, :integer

  belongs_to :manager, resource: PersonResource, writable: false
  belongs_to :managed, resource: PersonResource, writable: false

  private

  def authorize_create(model)
    raise CanCan::AccessDenied unless FeatureGate.enabled?("people.people_managers.api")

    invalid_request!(:manager_id, :blank) if model.manager_id.blank?
    invalid_request!(:managed_id, :blank) if model.managed_id.blank?

    authorize!(:create_manager, model)
    authorize!(:create_managed, model)
  end

  def authorize_destroy(model)
    raise CanCan::AccessDenied unless FeatureGate.enabled?("people.people_managers.api")

    authorize!(:destroy_manager, model)
    authorize!(:destroy_managed, model)
  end
end
