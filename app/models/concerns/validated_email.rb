# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ValidatedEmail

  extend ActiveSupport::Concern

  included do
    validate :assert_valid_email
  end

  def valid_email?
    Truemail.valid?(email)
  end

  private

  def assert_valid_email
    self.email = email.presence
    return unless email

    unless valid_email?
      errors.add(:email, :invalid)
    end
  end

end
