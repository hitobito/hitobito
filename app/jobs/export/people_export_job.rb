# frozen_string_literal: true

#  Copyright (c) 2017-2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::PeopleExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:group_id, :list_filter_args]

  def initialize(format, user_id, group_id, list_filter_args, options: {})
    super(format, user_id, options: options)
    @group_id = group_id
    @list_filter_args = list_filter_args
    restrict_to_roles
  end

  private

  def restrict_to_roles
    if @options[:show_related_roles_only]
      @options.merge!(related_group_roles.as_options)
    end
  end

  def related_group_roles
    Export::Tabular::People::GroupRoles::Filter.new(@group_id, @list_filter_args)
  end

  def entries
    entries = filter.entries
    if full?
      full_entries(entries)
    else
      entries.preload_public_accounts.includes(:primary_group)
    end
  end

  def full_entries(entries)
    entries
      .select('people.*')
      .preload_accounts
      .includes(relations_to_tails: :tail, qualifications: { qualification_kind: :translations })
      .includes(:primary_group)
  end

  def data
    return super unless @options[:selection]

    table_display = TableDisplay.for(@user_id, Person)
    Export::Tabular::People::TableDisplays.export(@format, entries, table_display)
  end

  def exporter
    return Export::Tabular::People::Households if @options[:household]
    return Export::Tabular::People::TableDisplays if @options[:selection]
    return Export::Tabular::People::PeopleFull if full?

    Export::Tabular::People::PeopleAddress
  end

  def full?
    @options[:full]
  end

  def filter
    @filter ||= Person::Filter::List.new(Group.find(@group_id), user, @list_filter_args)
  end
end
