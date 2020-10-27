# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PersonDuplicateTableBuilder

  I18N_PREFIX = 'person_duplicates'.freeze
  I18N_PERSON = 'activerecord.attributes.person'.freeze
  I18N_PERSON_DUPLICATE = 'activerecord.attributes.person_duplicate'.freeze
  TABLE_CLASS = 'table table-hover'.freeze

  attr_reader :template
  delegate :can?, :content_tag, :content_tag_nested, :action_button, to: :template

  def initialize(entries, group, template)
    @template = template
    @entries = entries
    @group = group
    @cols = [:first_name, :last_name, :nickname, :company_name,
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
            blank_row unless @entries.last == e
      end
    end
  end

  def person_row(entry, pnr)
    person = entry.send(pnr)
    content_tag_nested(:tr, @cols) do |c|
      if c == :actions
        action_col(entry, pnr) if pnr == :person_1
      else
        content_tag(:td, person.send(c))
      end
    end
  end

  def action_col(entry, pnr)
    content_tag(:td, class: 'right vertical-middle', rowspan: 2) do
      content = ''
      if can?(:merge, entry)
        content += action_button_merge(entry)
      end
      if can?(:acknowledge, entry)
        content += action_button_acknowledge(entry)
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

  def action_button_acknowledge(entry)
    action_button(t('acknowledge.action'),
                  new_acknowledge_path(entry),
                  :'user-slash',
                  remote: true)
  end

  def new_merge_path(entry)
    template.new_merge_group_person_duplicate_path(
      group_id: @group.id,
      id: entry.id)
  end

  def new_acknowledge_path(entry)
    template.new_acknowledge_group_person_duplicate_path(
      group_id: @group.id,
      id: entry.id)
  end


  def blank_row
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
