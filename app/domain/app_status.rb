# frozen_string_literal: true

#  Copyright (c) 2018-2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AppStatus
  class << self
    def auth_token
      @auth_token ||= begin
        token = Digest::SHA256.new.hexdigest(secret_key_base)
        token[40..]
      end
    end

    private

    def secret_key_base
      Hitobito::Application.secret_key_base
    end
  end

  def details
    {}
  end

  def code
    :service_unavailable
  end
end
