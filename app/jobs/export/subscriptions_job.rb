#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubscriptionsJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:mailing_list_id]

  # avoid long-running exports if only one is allowed at the same time.
  #
  # this could block exports for a long time. If a higher concurrency is allowed,
  # then the problem is known and can be mitigated with a higher concurrency.
  if Settings.delayed_jobs.concurrency.limit > 1
    self.max_run_time = 24.hours
  end

  def initialize(format, user_id, mailing_list_id, options)
    super(format, user_id, options)
    @mailing_list_id = mailing_list_id
  end

  private

  def data
    return super unless @options[:selection]

    table_display = TableDisplay.for(@user_id, Person)
    Export::Tabular::People::TableDisplays.export(@format, entries, table_display)
  end

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end

  def entries
    mailing_list.people.preload_public_accounts.includes(:primary_group).order_by_name
  end

  def exporter
    return Export::Tabular::People::Households if @options[:household]
    return Export::Tabular::People::TableDisplays if @options[:selection]

    Export::Tabular::People::PeopleAddress
  end
end
