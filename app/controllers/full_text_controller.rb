# frozen_string_literal: true

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class FullTextController < ApplicationController
  include FullTextSearchStrategy

  skip_authorization_check

  helper_method :entries, :tab_class

  respond_to :html

  def index
    @people = with_query { search_strategy.list_people }
    @groups = with_query { search_strategy.query_groups }
    @events = with_query { decorate_events(search_strategy.query_events) }
    @invoices = with_query { decorate_invoices(search_strategy.query_invoices) }
    @active_tab = active_tab
  end

  def query
    people = search_strategy.query_people.collect { |i| PersonDecorator.new(i).as_quicksearch }
    groups = search_strategy.query_groups.collect { |i| GroupDecorator.new(i).as_quicksearch }
    events = search_strategy.query_events.collect { |i| EventDecorator.new(i).as_quicksearch }
    invoices = search_strategy.query_invoices.collect { |i| InvoiceDecorator.new(i).as_quicksearch }

    render json: results_with_separator(people, groups, events, invoices) || []
  end

  private

  def results_with_separator(*sets)
    sets.select(&:present?).inject do |memo, set|
      memo + [{ label: '—' * 20 }] + set
    end
  end

  def entries
    @people
  end

  def with_query
    query_param.to_s.size >= 2 ? yield : []
  end

  def active_tab
    return :people if @people.present?
    return :groups if @groups.present?
    return :events if @events.present?
    return :invoices if @invoices.present?

    :people
  end

  def tab_class(tab)
    'active' if @active_tab == tab
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
end
