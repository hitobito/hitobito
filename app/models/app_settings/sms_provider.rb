# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

module AppSettings
  class SmsProvider
    include Encryptable

    attr_accessor :provider, :encrypted_username, :encrypted_password
    attr_encrypted :username, :password
  end
end
