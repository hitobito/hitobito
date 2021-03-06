# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicateTableBuilder

  I18N_PREFIX = 'person_duplicates'.freeze
  I18N_PERSON = 'activerecord.attributes.person'.freeze
  I18N_PERSON_DUPLICATE = 'activerecord.attributes.person_duplicate'.freeze
  TABLE_CLASS = 'table person-duplicates-table'.freeze

  attr_reader :template

  delegate :can?, :group_person_path, :link_to,
    :content_tag, :content_tag_nested,
    :action_button, to: :template

  def initialize(entries, group, template)
    @template = template
    @entries = entries
    @group = group
    @cols = [:person_name, :company_name,
             :birth_year, :town, :roles_list, :actions]
  end

  def self.table(entries, group, template)
    t = new(entries, group, template)
    t.to_html
  end

  def to_html
    content_tag(:table, class: TABLE_CLASS) do
      content_tag(:thead, html_header) +
        content_tag_nested(:tbody, @entries) do |e|
          person_row(e, :person_1) +
            person_row(e, :person_2) +
            divider_row(e)
      end
    end
  end

  def person_row(entry, p_nr)
    person = entry.send(p_nr)
    content_tag_nested(:tr, @cols) do |c|
      if c == :actions
        action_col(entry, p_nr) if p_nr == :person_1
      elsif c == :person_name
        content_tag(:td, label(person))
      else
        content_tag(:td, person.send(c))
      end
    end
  end

  def label(person)
    label = person.person_name
    if can?(:show, person) && person.roles.present?
      link_to(label,
              group_person_path(person.primary_group, person),
              target: '_blank')
    else
      label
    end
  end

  def action_col(entry, p_nr)
    content_tag(:td, class: 'right vertical-middle', rowspan: 2) do
      content = ''
      if can?(:merge, entry)
        content += action_button_merge(entry)
      end
      if can?(:ignore, entry)
        content += action_button_ignore(entry)
      end
      content.html_safe
    end
  end

  def action_button_merge(entry)
    action_button(t('merge.action'),
                  new_merge_path(entry),
                  :'user-friends',
                  remote: true)
  end

  def action_button_ignore(entry)
    action_button(t('ignore.action'),
                  new_ignore_path(entry),
                  :'user-slash',
                  remote: true)
  end

  def new_merge_path(entry)
    template.new_merge_group_person_duplicate_path(
      group_id: @group.id,
      id: entry.id)
  end

  def new_ignore_path(entry)
    template.new_ignore_group_person_duplicate_path(
      group_id: @group.id,
      id: entry.id)
  end


  def divider_row(entry) 
    return '' if @entries.last == entry

    content_tag(:tr, class: 'divider') do
      content_tag(:td, colspan: @cols.count) do
        ''
      end
    end
  end

  def html_header
    content_tag_nested(:tr, @cols) do |c|
      content_tag :th, translate_header(c)
    end
  end

  def translate_header(header)
    return if header == :actions

    I18n.t("#{I18N_PERSON}.#{header}",
      default: I18n.t("#{I18N_PERSON_DUPLICATE}.#{header}")
     )
  end

  def t(key)
    I18n.t("#{I18N_PREFIX}.#{key}")
  end
end
