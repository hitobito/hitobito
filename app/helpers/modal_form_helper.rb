# frozen_string_literal: true

#  Copyright (c) 2020, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ModalFormHelper

  # Render a generic modal form for the current entry
  def modal_entry_form(*attrs, &block)
    options = attrs.extract_options!
    buttons = options[:buttons] || true
    options[:builder] ||= StandardFormBuilder
    options[:html] ||= {}
    attrs = attrs_or_default(attrs) { default_attrs - [:created_at, :updated_at] }
    standard_form(path_args(entry), options) do |form|
      content = content_tag(:div, class: 'modal-body') do
        content_tag(:div, class: 'row-fluid') do
          c = form.error_messages
          c << form.labeled_input_fields(*attrs)
          c
        end
      end
      content << modal_submit_buttons(form)
      content.html_safe
    end
  end

  def modal_submit_buttons(form, submit_label: ti(:'button.save'))
    onclick = "event.preventDefault(); $('#modal-crud').modal('hide')"

    content_tag(:div, class: 'modal-footer') do
      btns = content_tag(:div, class: 'btn-group') do
        form.button(submit_label, class: 'btn btn-primary')
      end
      btns << link_to(ti(:"button.cancel"), '#', onclick: onclick, class: 'link cancel')

      btns
    end
  end

end
