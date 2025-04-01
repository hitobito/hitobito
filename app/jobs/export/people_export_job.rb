# frozen_string_literal: true

#  Copyright (c) 2017-2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::PeopleExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:group_id, :list_filter_args]

  def initialize(format, user_id, group_id, list_filter_args, options)
    super(format, user_id, options)
    @group_id = group_id
    @list_filter_args = list_filter_args
  end

  private

  def entries
    entries = filter.entries
    entries = Person.none unless entries.exists?
    if full?
      full_entries(entries)
    else
      entries.preload_public_accounts.includes(:primary_group)
    end
  end

  def full_entries(entries)
    entries
      .select("people.*")
      .preload_accounts
      .includes(qualifications: {qualification_kind: :translations})
      .includes(:primary_group)
  end

  def data
    return super unless @options[:selection]

    table_display = TableDisplay.for(@user_id, Person)
    Export::Tabular::People::TableDisplays.export(@format, entries, table_display, group)
  end

  def exporter
    return Export::Tabular::People::Households if @options[:household]
    return Export::Tabular::People::TableDisplays if @options[:selection]
    return Export::Tabular::People::PeopleFull if full?

    Export::Tabular::People::PeopleAddress
  end

  def full?
    @options[:full] && index_full_ability?
  end

  def index_full_ability?
    @index_full_ability ||= if filter.multiple_groups
      ability.can?(:index_deep_full_people, group)
    else
      ability.can?(:index_full_people, group)
    end
  end

  def filter
    @filter ||= Person::Filter::List.new(group, user, @list_filter_args)
  end

  def group
    @group ||= Group.find(@group_id)
  end
end
