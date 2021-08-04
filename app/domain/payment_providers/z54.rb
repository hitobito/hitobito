# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/MethodLength, Metrics/LineLength, Metrics/AbcSize
class PaymentProviders::Z54 < Epics::GenericRequest

  attr_accessor :from, :to

  def initialize(client, from = nil, to = nil)
    super(client)
    self.from = from
    self.to = to
  end

  def header
    Nokogiri::XML::Builder.new do |xml|
      xml.header(authenticate: true) {
        xml.static {
          xml.HostID host_id
          xml.Nonce nonce
          xml.Timestamp timestamp
          xml.PartnerID partner_id
          xml.UserID user_id
          xml.Product("EPICS - a ruby ebics kernel", 'Language' => 'de')
          xml.OrderDetails {
            xml.OrderType 'Z54'
            xml.OrderAttribute 'DZHNN'
            if !!from && !!to
              xml.StandardOrderParams {
                xml.DateRange {
                  xml.Start from
                  xml.End to
                }
              }
            else
              xml.StandardOrderParams
            end
          }
          xml.BankPubKeyDigests {
            xml.Authentication(client.bank_x.public_digest, Version: 'X002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256")
            xml.Encryption(client.bank_e.public_digest, Version: 'E002', Algorithm: "http://www.w3.org/2001/04/xmlenc#sha256" )
          }
          xml.SecurityMedium '0000'
        }
        xml.mutable {
          xml.TransactionPhase 'Initialisation'
        }
      }
    end.doc.root
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/LineLength, Metrics/AbcSize
