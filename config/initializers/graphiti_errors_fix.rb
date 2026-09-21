# frozen_string_literal: true

#  Copyright (c) 2012-2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# graphiti_errors builds nested validation errors by matching each of a model's
# *currently associated* related records (`model.send(name)`, i.e. every existing
# row, not just the ones touched by this request) against the request's relationship
# payload array via temp-id/id. Any related record that was already associated before
# this request (e.g. a person's other, untouched social accounts) has no corresponding
# payload entry, so the match returns nil -- and upstream then crashes on
# `payload[:meta][:jsonapi_type]` for that nil. Skip such untouched records instead.
#
# graphiti_errors is deprecated as of now and will be integrated per graphiti 2.0
# so I opted to monkey patch it for now
GraphitiErrors::Validation::Serializer.class_eval do
  private

  def traverse_relationships(model, relationship_params)
    return unless relationship_params

    relationship_params.each_pair do |name, payload|
      Array(model.send(name)).each do |relationship_object|
        related_payload = payload
        if payload.is_a?(Array)
          related_payload = matching_payload(payload, relationship_object)
          next unless related_payload
        end

        yield name, relationship_object, related_payload
        relationship_errors(relationship_object, related_payload[:relationships])
      end
    end
  end

  def matching_payload(payload, relationship_object)
    temp_id = relationship_object.instance_variable_get(:@_jsonapi_temp_id)
    payload.find do |p|
      p[:meta][:temp_id] === temp_id ||
        p[:meta][:id] == relationship_object.id.to_s
    end
  end
end
