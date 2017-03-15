# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module EventKindsHelper

  def labeled_qualification_kinds_field(form, collection, category, role, title)
    selected = entry.qualification_kinds(category, role)

    # Unify collection with selected, to include them even if they are marked as deleted.
    options = collection | selected

    form.labeled(title) do
      select_tag("event_kind[qualification_kinds][#{role}][#{category}][qualification_kind_ids]",
                 options_from_collection_for_select(options, :id, :to_s,
                                                    selected.collect(&:id)),
                 multiple: true,
                 class: 'span6')
    end
  end

  def grouped_qualification_kinds_string(kind, category, role)
    kinds = kind.qualification_kinds(category, role).group_by(&:id)
    grouped_ids = kind.grouped_qualification_kind_ids(category, role)
    or_separator = [
      ' ',
      content_tag(:span, t('event.kinds.qualifications.or'), class: 'muted'),
      ' '
    ]
    safe_join(grouped_ids, safe_join(or_separator)) do |ids|
      ids.collect { |id| kinds[id].first.to_s }.sort.to_sentence
    end
  end

end
