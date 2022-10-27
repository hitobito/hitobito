# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::SubscriptionsJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:mailing_list_id, :options]

  def initialize(format, user_id, mailing_list_id, options: {})
    super(format, user_id, options: options)
    @mailing_list_id = mailing_list_id
    restrict_to_roles
  end

  private

  def restrict_to_roles
    if @options[:show_related_roles_only]
      @options.merge!(group_roles.as_options)
    end
  end

  def group_roles
    Export::Tabular::People::GroupRoles::MailingList.new(mailing_list)
  end

  def as_options
    { restrict_to_roles: role_sti_names,
      restrict_to_group_ids: group_ids }
  end

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end

  def entries
    mailing_list.people.preload_public_accounts.includes(:primary_group).order_by_name
  end

  def exporter
    return Export::Tabular::People::Households if @options[:household]

    Export::Tabular::People::PeopleAddress
  end

end
