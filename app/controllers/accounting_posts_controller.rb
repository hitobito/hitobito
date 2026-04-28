# frozen_string_literal: true

#  Copyright (c) 2006-2017, Puzzle ITC GmbH. This file is part of
#  PuzzleTime and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/puzzletime.

class AccountingPostsController < CrudController
  include WithPeriod
  include CockpitCsv

  self.nesting = [Order]

  self.permitted_attrs = [:closed, :offered_hours, :offered_rate, :offered_total,
                          :remaining_hours, :portfolio_item_id, :service_id, :billable,
                          :description_required, :ticket_required, :from_to_times_required,
                          :meal_compensation, :billing_reminder_active,
                          { work_item_attributes: %i[name shortname description] }]

  helper_method :order

  def index
    set_period
    @period = Period.new(@period.start_date, Time.zone.today) if @period.end_date.blank?
    @cockpit = Order::Cockpit.new(parent, @period)
  end

  def new
    @portfolio_items = PortfolioItem.active
    @services = Service.active
  end

  def edit
    @portfolio_items = PortfolioItem.active_or_selected(@accounting_post.portfolio_item_id)
    @services = Service.active_or_selected(@accounting_post.service_id)
  end

  def export_csv
    set_period
    @period = Period.new(@period.start_date, Time.zone.today) if @period.end_date.blank?
    @cockpit = Order::Cockpit.new(parent, @period)
    send_cockpit_csv(@cockpit, cockpit_csv_filename)
  end

  private

  def cockpit_csv_filename
    name = 'accounting_posts'
    name += @period&.start_date ? "_#{@period.start_date.strftime('%Y-%m-%d')}" : '_egal'
    name += @period.end_date ? "_#{@period.end_date.strftime('%Y-%m-%d')}" : '_egal'

    "#{name}.csv"
  end

  def find_entry
    super
  rescue ActiveRecord::RecordNotFound
    # happens when changing order in top dropdown while editing accounting post.
    redirect_to order_accounting_posts_path(order)
    AccountingPost.new
  end

  def build_entry
    super.tap { |p| p.build_work_item(parent_id: order.work_item_id) }
  end

  def assign_attributes
    entry.attributes = model_params.except(:work_item_attributes)
    entry.attach_work_item(order, model_params[:work_item_attributes], book_on_order?)
  end

  def book_on_order?
    params[:book_on_order].to_s == 'true'
  end

  def index_path
    order_accounting_posts_path(parent)
  end

  def order
    parent
  end
end
