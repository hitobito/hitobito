# frozen_string_literal: true

#  Copyright (c) 2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PaymentProviderConfigs::IniLetterController < ApplicationController

  def show
    authorize!(:show, entry.invoice_config)

    send_data payment_provider.ini_letter, type: 'text/html', disposition: 'inline'
  end

  private

  def payment_provider
    PaymentProvider.new(entry)
  end

  def entry
    @entry ||= PaymentProviderConfig.find(params[:id])
  end
end
