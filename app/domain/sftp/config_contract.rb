# frozen_string_literal: true

#  Copyright (c) 2025, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class Sftp::ConfigContract < Dry::Validation::Contract
  params do
    required(:host).filled(:string)
    optional(:port).maybe(:integer)
    required(:user).filled(:string)
    optional(:password).maybe(:string)
    optional(:private_key).maybe(:string)
    required(:remote_path).filled(:string)
  end

  rule(:port) do
    if key? && value && value <= 0
      key.failure("must be greater than 0")
    end
  end

  rule(:password, :private_key) do
    if values[:password].nil? && values[:private_key].nil?
      key.failure("must be present if private_key is not given")
    end
  end
end
