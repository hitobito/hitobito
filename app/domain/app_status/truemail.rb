# frozen_string_literal: true

#  Copyright (c) 2017-2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus::Truemail < AppStatus

  def initialize
    @truemail_working = truemail_working
  end

  def details
    { truemail_working: @truemail_working,
      validated_email: verification_email }
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
