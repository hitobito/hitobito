# encoding: utf-8

#  Copyright (c) 2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactableSerializer

  def contact_accounts(only_public)
    entities :additional_emails,
             filter_accounts(item.additional_emails, only_public),
             AdditionalEmailSerializer

    entities :phone_numbers,
             filter_accounts(item.phone_numbers, only_public),
             PhoneNumberSerializer

    entities :social_accounts,
             filter_accounts(item.social_accounts, only_public),
             SocialAccountSerializer
  end

  private

  def filter_accounts(accounts, only_public)
    accounts.select { |a| a.public? || !only_public }
  end

end
