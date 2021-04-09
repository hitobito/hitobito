# frozen_string_literal: true

module Api
  class EventParticipationsController < ApplicationController
    def index
      authorize!(:show, person)

      respond_to do |format|
        format.json do
          render json: ListSerializer.new(list_entries.decorate,
                                          group: person.primary_group,
                                          serializer: EventParticipationSerializer,
                                          controller: self)
        end
      end
    end

    private

    def list_entries
      Event::Participation.includes(:roles, event: :translations).where(person: person)
    end

    def person
      @person ||= Person.includes(:primary_group).find(params[:person_id])
    end
  end
end
