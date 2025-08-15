# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddressSynchronizationJob < CursorBasedPagingJob
  attr_reader :batch_token, :upload_token, :result_token, :data
  self.parameters += [:batch_token, :upload_token, :result_token]
  self.progress_message = "Post Adressabgleich: Fortschritt %d%%"
  self.log_category = Synchronize::Addresses::SwissPost::Config::LOG_CATEGORY

  def self.exists?
    Delayed::Job.where("handler LIKE ?", "%#{name}%").exists?
  end

  def initialize(cursor: nil, batch_token: nil, upload_token: nil, result_token: nil,
    processed_count: 0, processing_count: 0)
    super(cursor:, processed_count:, processing_count:)
    @batch_token = batch_token
    @upload_token = upload_token
    @result_token = result_token
  end

  def success(job)
    create_attachment(job) if job.payload_object.data
  end

  private

  def reschedule(attrs = {batch_token:, upload_token:, result_token:, cursor:, processed_count:, processing_count:}) = super # rubocop:disable Layout/LineLength

  def process_next_batch
    super do
      result_token = client.create_file
      upload_token = client.upload_file(generate_data(batch))
      batch_token = client.run_batch(upload_token, result_token)

      {
        batch_token:,
        upload_token:,
        result_token:,
        cursor: batch.last.id,
        processed_count: processed_count + processing_count,
        processing_count: batch.count
      }
    end
  end

  def log_error
    super("Post Adressabgleich: Fehler beim Verarbeiten von #{upload_token}")
  end

  def process_result
    @data = client.download_file(result_token)
    Synchronize::Addresses::SwissPost::ResultProcessor.new(data).process
  end

  def scope
    Person
      .joins(:roles)
      .where(config.role_types ? {roles: {type: config.role_types}} : {})
      .where(Synchronize::Addresses::SwissPost::Config.person_constraints)
      .order(:id)
      .distinct
  end

  def check_batch
    return :none if batch_token.blank?
    token_state = client.check_batch_status(batch_token)
    if token_state == 4
      :finished
    elsif [0, 2, 3].include?(token_state)
      :processing
    else
      :error
    end
  end

  def generate_data(batch)
    Synchronize::Addresses::SwissPost::Generator.new(batch).generate
  end

  def client
    @client ||= Synchronize::Addresses::SwissPost::Client.new
  end

  def config
    @config ||= Synchronize::Addresses::SwissPost::Config
  end

  def create_attachment(job)
    blob = ActiveStorage::Blob.create_and_upload!(
      filename: result_token,
      io: StringIO.new(data),
      content_type: "application/text"
    )
    attachment = ActiveStorage::Attachment.new(name: result_token, record: job, blob:)
    attachment.define_singleton_method(:transform_variants_later, -> {
    }) # NOTE: remove for rails => 7.2
    attachment.save!
  end
end
