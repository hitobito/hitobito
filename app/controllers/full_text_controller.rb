# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FullTextController < ApplicationController
  skip_authorization_check

  helper_method :entries, :active_tab_class

  respond_to :html

  SEARCHABLE_MODELS = [
    [:people, SearchStrategies::PersonSearch],
    [:groups, SearchStrategies::GroupSearch],
    [:events, SearchStrategies::EventSearch],
    [:invoices, SearchStrategies::InvoiceSearch, -> { current_ability.can?(:index, Invoice) }]
  ].freeze

  def index
    respond_to do |format|
      format.html { query_results }
      format.json do
        render json: query_json_results || []
      end
    end
  end

  private

  def query_results # rubocop:todo Metrics/AbcSize
    each_search_result do |key, result|
      if key == :invoices || key == :events
        instance_variable_set(:"@#{key}", with_query { send(:"decorate_#{key}", result) })
      else
        instance_variable_set(:"@#{key}", with_query { result })
      end
    end

    if only_result.present?
      redirect_to polymorphic_path(only_result)
    else
      @active_tab = active_tab
    end
  end

  def query_json_results
    each_search_result do |key, result|
      instance_variable_set(
        :"@#{key}", result.collect { |i|
          "#{key.to_s.singularize.titleize}Decorator"
            .constantize.new(i)
            .as_quicksearch
        }
      )
    end

    results_with_separator(@people, @groups, @events, @invoices)
  end

  def each_search_result(limit: nil)
    SEARCHABLE_MODELS.each do |key, search_class, condition|
      next if condition && !instance_exec(&condition)
      yield key, search_class.new(current_user, query_param, params[:page], limit:).search_fulltext
    end
  end

  def results_with_separator(*sets)
    sets.select(&:present?).inject do |memo, set|
      memo + [{label: "—" * 20}] + set
    end
  end

  # return the only result if the search term only matches a single result for all searchable models
  def only_result
    all_results = [@people, @invoices, @events, @groups].compact.flatten
    all_results.first if all_results.size == 1
  end

  def entries
    @people
  end

  def with_query
    (query_param.to_s.size >= 2) ? yield : []
  end

  def active_tab
    return :people if @people.present?
    return :groups if @groups.present?
    return :events if @events.present?
    return :invoices if @invoices.present?

    :people
  end

  def active_tab_class(tab)
    "active" if @active_tab == tab
  end

  def decorate_events(events)
    events.map do |event|
      EventDecorator.new(event)
    end
  end

  def decorate_invoices(invoices)
    invoices.map do |invoice|
      InvoiceDecorator.new(invoice)
    end
  end

  def query_param
    params[:q]
  end
end
