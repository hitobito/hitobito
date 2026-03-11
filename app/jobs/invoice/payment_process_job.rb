#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Invoice::PaymentProcessJob < BaseJob
  self.parameters = [:xml_file_id]

  def initialize(xml_file_id)
    super()
    @xml_file_id = xml_file_id
  end

  def perform
    processor.process
  end

  private

  def processor = @processor ||= Invoice::PaymentProcessor.new(xml_file.download)

  def xml_file = @xml_file ||= ActiveStorage::Blob.find(@xml_file_id)
end
