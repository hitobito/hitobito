# encoding: utf-8

#  Copyright (c) 2012-2017, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

module ContactAttrs
  class ControlBuilder

    include ActionView::Helpers::OutputSafetyHelper

    def initialize(form, event)
      @f = form
      @event = event
    end

    def render
      safe_join([mandatory_contact_attrs, configurable_contact_attrs, contact_associations])
    end

    private

    delegate :t, to: I18n

    attr_reader :f, :event

    def mandatory_contact_attrs
      Event::ParticipationContactData::MANDATORY_CONTACT_ATTRS.collect do |a|
        [f.label(a, attr_label(a), class: 'control-label'),
        radio_buttons(a, true, [:required]),
        line_break]
      end
    end

    def configurable_contact_attrs
      non_mandatory_contact_attrs.collect do |a|
        [f.label(a, attr_label(a), class: 'control-label'),
        radio_buttons(a),
        line_break]
      end
    end

    def non_mandatory_contact_attrs
      Event::ParticipationContactData::CONTACT_ATTRS -
        Event::ParticipationContactData::MANDATORY_CONTACT_ATTRS
    end

    def contact_associations
      Event::ParticipationContactData::CONTACT_ASSOCIATIONS.collect do |a|
        [f.label(a, attr_label(a), class: 'control-label'),
        assoc_checkbox(a),
        line_break]
      end
    end

    def radio_buttons(attr, disabled = false, options = [:required, :optional, :hidden])
      f.content_tag(:div, class: 'controls') do
        buttons = options.collect do |o|
          checked = options.size == 1
          radio_button(attr, disabled, o, checked)
        end
        safe_join(buttons)
      end
    end

    def radio_button(attr, disabled, option, checked = false)
      f.label("#{for_label(attr)}_#{option}", class: 'radio inline') do
        checked = checked ? checked : checked?(attr, option)
        options = {disabled: disabled, checked: checked}
        f.radio_button(for_label(attr), option, options) +
          option_label(option)
      end
    end

    def assoc_checkbox(assoc)
      f.content_tag(:div, class: 'controls') do
        f.label(for_label(assoc), class: 'checkbox inline') do
          options = {checked: assoc_hidden?(assoc)}
          f.check_box(for_label(assoc), options, :hidden) +
            option_label(:hidden)
        end
      end
    end

    def assoc_hidden?(assoc)
      event.hidden_contact_attrs.include?(assoc.to_s)
    end

    def checked?(attr, option)
      attr = attr.to_s
      required = event.required_contact_attrs.include?(attr)
      hidden = event.hidden_contact_attrs.include?(attr)
      return required if option == :required
      return hidden if option == :hidden
      !required && !hidden
    end

    def for_label(attr)
      "contact_attrs[#{attr}]"
    end

    def option_label(option)
      t("activerecord.attributes.event/contact_attrs.#{option}")
    end

    def attr_label(attr)
      t("activerecord.attributes.person.#{attr}")
    end

    def line_break
      '<br/>'.html_safe
    end

  end
end
