# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoices::EvaluationsController < ApplicationController
  prepend Nestable

  decorates :group

  before_action :authorize_action
  prepend_before_action :entries
  prepend_before_action :group
  prepend_before_action :total

  private

  def group
    @group ||= Group.find(params[:group_id])
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
    params[:from] || 1.month.ago.to_date
  end

  def to
    params[:to] || Time.zone.today
  end

  def authorize_action
    authorize!(:index_invoices, group)
  end
end
