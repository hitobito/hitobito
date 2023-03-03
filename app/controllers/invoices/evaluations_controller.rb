# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoices::EvaluationsController < ApplicationController
  prepend Nestable

  decorates :group
  helper_method :group, :from, :to

  before_action :authorize_action
  prepend_before_action :entries
  prepend_before_action :group
  prepend_before_action :total

  def show
    respond_to do |format|
      format.html { render }
      format.csv { render_tabular(:csv) }
      format.xlsx { render_tabular(:xlsx) }
    end
  end

  private

  def render_tabular(format)
    exported_data = case format
                    when :csv then Export::Tabular::Invoices::EvaluationList.csv(table_rows)
                    when :xlsx then Export::Tabular::Invoices::EvaluationList.xlsx(table_rows)
                    end
    send_data exported_data, type: format, filename: "invoices_evaluation_#{from}-#{to}.#{format}"
  end

  def group
    @group ||= Group.find(params[:group_id])
  end

  def table_rows
    @table_rows ||= @entries + total_row
  end

  def total_row
    [{
      name: t('.table.total'),
      amount_paid: total
    }]
  end

  def entries
    @entries ||= evaluation.fetch_evaluations
  end

  def evaluation
    @evaluation ||= Invoice::ItemEvaluation.new(group, from, to)
  end

  def total
    @total ||= evaluation.total
  end

  def from
    Date.parse(params[:from])
  rescue
    1.month.ago.to_date
  end

  def to
    Date.parse(params[:to])
  rescue
    Time.zone.today
  end

  def authorize_action
    authorize!(:index_invoices, group)
  end
end
