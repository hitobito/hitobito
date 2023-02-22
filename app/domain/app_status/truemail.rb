# frozen_string_literal: true

#  Copyright (c) 2017-2023, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Truemail < AppStatus

  def initialize(with_private_details = false)
    super()

    @truemail_working = truemail_working
    @with_private_details = with_private_details
  end

  def details
    details = { truemail_working: @truemail_working }

    if @with_private_details
      details[:validated_email] = verification_email
    end

    details
  end

  def code
    @truemail_working ? :ok : :service_unavailable
  end

  private

  def truemail_working
    ::Truemail.valid?(verification_email)
  end

  def verification_email
    ::Truemail.configure.verifier_email
  end

end
