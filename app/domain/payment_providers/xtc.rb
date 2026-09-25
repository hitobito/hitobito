# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/MethodLength, Layout/LineLength, Metrics/AbcSize
class PaymentProviders::Xtc < Epics::GenericUploadRequest
  def document_digest
    @crypt_service.hash(normalized_document)
  end

  def normalized_document
    document.gsub(/\n|\r/, "")
  end

  def document=(value)
    @document = value
  end

  def to_xml
    # builder = request_factory.create_btu(transaction_key, document_digest, 1, **{ service_name: 'OTH', scope: 'BIL', service_option: "CH004TPS", msg_name: 'csv', filename: 'ccs.csv.xxx.csv' }) # zkb
    builder = request_factory.create_btu(transaction_key, document_digest, 1, **{ service_name: "OTH", scope: "BIL", service_option: "CH002LMF", msg_name: "csv", filename: "ccs.csv.xxx.csv" }) # postfinance
    builder.to_xml
  end
end
# rubocop:enable Metrics/MethodLength, Layout/LineLength, Metrics/AbcSize
