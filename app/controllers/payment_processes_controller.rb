#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentProcessesController < ApplicationController
  before_action :authorize_action

  helper_method :group, :parent, :processor, :parents

  def new
  end

  def show
    unless valid_file?(file_param)
      redirect_to new_group_payment_process_path(group), alert: t("payment_processes.invalid_file")
    end
  end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    if valid_file?(file_param)
      enqueue_read_payment_process_job
      render :show
    elsif params[:xml_file_id]
      enqueue_payment_process_job
      redirect_to group_invoices_path(group), notice: t("payment_processes.job_enqueued")
    elsif @parsing_error
      redirect_to new_group_payment_process_path(group), alert: t("payment_processes.parsing_error",
        error: @parsing_error)
    else
      redirect_to new_group_payment_process_path(group), alert: t("payment_processes.invalid_file")
    end
  end

  private

  def enqueue_read_payment_process_job
    Invoice::ReadPaymentProcessJob.new(
      current_user.id,
      "preview-table",
      group.id,
      store_temporary_blob.id
    ).enqueue!
  end

  def enqueue_payment_process_job
    Invoice::PaymentProcessJob.new(params[:xml_file_id]).enqueue!
  end

  def store_temporary_blob
    ActiveStorage::Blob.create_temporary!(
      io: file_param,
      filename: file_param.original_filename,
      content_type: file_param.content_type
    )
  end

  def authorize_action
    authorize!(:index_issued_invoices, group)
  end

  def group
    @group = Group.find(params[:group_id])
  end

  alias_method :parent, :group

  def file_param
    params[:payment_process] && params[:payment_process][:file]
  end

  def valid_file?(io)
    io.present? &&
      io.respond_to?(:content_type) &&
      # windows sends csv files as application/vnd.excel, windows 10 as application/octet-stream
      io.content_type =~ %r{text/xml} &&
      io.tempfile.read.include?("BkToCstmrDbtCdtNtfctn") &&
      io.tempfile.rewind
  end

  def parents
    [parent]
  end
end
