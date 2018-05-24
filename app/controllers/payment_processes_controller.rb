#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentProcessesController < ApplicationController
  before_action :authorize_action

  helper_method :group, :parent, :processor

  def new; end

  def show
    unless processor
      redirect_to new_group_payment_process_path(group), alert: t('payment_processes.invalid_file')
    end
  end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    if valid_file?(file_param) && processor
      flash.now[:notice] = processor.notice
      flash.now[:alert] = processor.alert
      render :show
    elsif processor && params[:data]
      redirect_to group_invoices_path(group), notice: t('payment_processes.created',
                                                        count: processor.process)
    elsif @parsing_error
      redirect_to new_group_payment_process_path(group), alert: t('payment_processes.parsing_error',
                                                                  error: @parsing_error)
    else
      redirect_to new_group_payment_process_path(group), alert: t('payment_processes.invalid_file')
    end
  end

  def authorize_action
    authorize!(:index_invoices, group)
  end

  def group
    @group = Group.find(params[:group_id])
  end

  alias parent group

  def processor
    @processor ||= Invoice::PaymentProcessor.new(data)
  rescue => e
    @parsing_error = e
    nil
  end

  def file_param
    params[:payment_process] && params[:payment_process][:file]
  end

  def valid_file_or_data?
    valid_file?(file_param) || params[:data].present?
  end

  def data
    @data ||= read_file || params[:data]
  end

  def read_file
    file_param && valid_file?(file_param) && file_param.read.force_encoding('UTF-8')
  end

  def valid_file?(io)
    io.present? &&
    io.respond_to?(:content_type) &&
    # windows sends csv files as application/vnd.excel, windows 10 as application/octet-stream
    io.content_type =~ %r{text/xml}
  end

end
