# encoding: utf-8

#  Copyright (c) 2017, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::PeopleExportJob < Export::ExportBaseJob

  self.parameters = PARAMETERS + [:filter]

  def initialize(format, user_id, filter, options)
    super(format, user_id, options)
    @filter = filter
  end

  private

  def entries
    entries = @filter.entries
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

  def exporter
    return Export::Tabular::People::Households if  @options[:household]
    full? ? Export::Tabular::People::PeopleFull : Export::Tabular::People::PeopleAddress
  end

  def full?
    @options[:full]
  end
end
