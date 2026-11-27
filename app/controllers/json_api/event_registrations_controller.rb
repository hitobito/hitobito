# frozen_string_literal: true

#  Copyright (c) 2026, Berner Fachhochschule. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JsonApi::EventRegistrationsController < JsonApiController
  def create
    resource = resource_class.build(params.except(:id))
    if resource.save
      render json: without_links(resource), status: :created, content_type: MEDIA_TYPE
    else
      render jsonapi_errors: resource
    end
  end

  def event
    @event ||= Event.find(params[:id])
  end

  private

  def authorize_create
    authorize!(:register_participations, event)
  end

  # Pagination links would repeat the submitted personal data in their query strings.
  def without_links(resource)
    JSON.parse(resource.to_jsonapi).except("links")
  end
end
