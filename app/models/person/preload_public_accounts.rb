#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Person::PreloadPublicAccounts
  def self.extended(base)
    base.do_preload_public_accounts
  end

  def self.for(records)
    records = Array(records)

    # preload accounts
    ActiveRecord::Associations::Preloader.new.preload(records, :phone_numbers)
    ActiveRecord::Associations::Preloader.new.preload(records, :additional_emails)

    records
  end

  def do_preload_public_accounts
    @do_preload_public_accounts = true
  end

  private

  def exec_queries
    records = super

    Person::PreloadPublicAccounts.for(records) if @do_preload_public_accounts

    records
  end
end
