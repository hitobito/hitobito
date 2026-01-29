# frozen_string_literal: true

#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module InvoiceRuns
  class RecipientSourceBuilder
    attr_reader :params, :group

    def initialize(params, group)
      @params = params
      @group = group
    end

    def recipient_source
      @recipient_source ||= if filtered_source?
        build_filter_from_params
      else
        find_recipient_source
      end
    end

    private

    def build_filter_from_params
      if event_filter?
        Event::ParticipationsFilter.new(
          event: Event.find(filter_params["event_id"]),
          participant_type: filter_params.dig("filters", "participant_type").presence
        )
      else
        PeopleFilter.new(
          group: filter_group,
          range: filter_params["range"].presence || "deep",
          filter_chain: normalized_filter_chain
        )
      end
    end

    def find_recipient_source
      recipient_source_type.find(invoice_run_params[:recipient_source_id])
    end

    def normalized_filter_chain
      chain = if filter_params["filters"].is_a?(Hash)
        filter_params["filters"].with_indifferent_access
      else
        {}
      end

      if recipient_ids.any?
        chain[:attributes] ||= {}
        chain[:attributes]["0"] = {
          "constraint" => "include",
          "key" => "id",
          "value" => recipient_ids
        }
      end

      chain.presence
    end

    def recipient_ids
      return [] unless params[:ids]

      params[:ids].split(",").map(&:to_i)
    end

    def filter_params
      return {} if params[:filter].blank?

      @filter_params ||= case params[:filter]
      when String then JSON.parse(params[:filter])
      when ActionController::Parameters then params[:filter].to_unsafe_hash
      else {}
      end
    end

    # Use current group when no group_id from filter params is passed
    def filter_group
      group_id = filter_params["group_id"]
      group_id ? Group.find(group_id) : group
    end

    def recipient_source_type
      type = invoice_run_params[:recipient_source_type]

      if InvoiceRun::RECIPIENT_TYPES.include?(type)
        type.constantize
      else
        raise "Invalid recipient_source_type"
      end
    end

    def filtered_source? = filter_params.present? || recipient_ids.present?

    def event_filter? = filter_params["event_id"].present?

    def invoice_run_params = params[:invoice_run] || {}
  end
end
