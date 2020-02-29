# encoding: utf-8

#  Copyright (c) 2012-2015, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FormHelper

  # Renders a generic form for the given object using StandardFormBuilder.
  def standard_form(object, options = {}, &block)
    options[:builder] ||= StandardFormBuilder
    options[:html] ||= {}
    add_css_class options[:html], 'form-horizontal' unless options.delete(:stacked)
    add_css_class options[:html], 'form-noindent' if options.delete(:noindent)

    form_for(object, options, &block) + send(:after_nested_form_callbacks)
  end

  # Render a generic form for the current entry
  def entry_form(*attrs, &block)
    options = attrs.extract_options!
    options[:buttons_bottom] = true unless options.key?(:buttons_bottom)
    options[:buttons_top] = true unless options.key?(:buttons_top)
    options[:cancel_url] ||= if controller.is_a?(SimpleCrudController)
                               polymorphic_path(path_args(model_class), returning: true)
                             else
                               polymorphic_path(path_args(entry))
                             end
    attrs = attrs_or_default(attrs) { default_attrs - [:created_at, :updated_at] }
    crud_form(path_args(entry), *attrs, options, &block)
  end

  # Renders a generic form for the given entry with :default_attrs or the
  # given attribute array, using the StandardFormBuilder. An options hash
  # may be given as the last argument.
  # If a block is given, a custom form may be rendered and attrs is ignored.
  def crud_form(object, *attrs, &block) # rubocop:disable Metrics/MethodLength
    options = attrs.extract_options!

    buttons_bottom = options.delete(:buttons_bottom)
    buttons_top = options.delete(:buttons_top) { true }
    form_button_options = options.slice(:add_another_label, :add_another, :submit_label)
                                 .merge(cancel_url: get_cancel_url(object, options))

    standard_form(object, options) do |form|
      content = form.error_messages

      content << form_buttons(form, form_button_options.merge(toolbar_class: 'top')) if buttons_top

      content << if block_given?
                   capture(form, &block)
                 else
                   form.labeled_input_fields(*attrs)
                 end

      if buttons_bottom
        content << form_buttons(form, form_button_options.merge(toolbar_class: 'bottom'))
      end

      content.html_safe
    end
  end

  def button_toolbar(form, toolbar_class:, &block)
    content_tag(:div, class: "btn-toolbar #{toolbar_class}") do
      capture(form, &block)
    end
  end

  def form_buttons(form, submit_label: ti(:"button.save"), cancel_url: nil, toolbar_class: nil,
                          add_another: false, add_another_label: ti(:"button.add_another"))
    button_toolbar(form, toolbar_class: toolbar_class) do
      content = submit_button(form, submit_label)
      content << add_another_button(form, add_another_label) if add_another.present?
      content << cancel_link(cancel_url) if cancel_url.present?

      content
    end
  end

  def add_another_button(form, label, options = {})
    content_tag(:div, class: 'btn-group') do
      form.button(label, options.merge(name: :add_another, class: 'btn btn-primary',
                                       data: { disable: true }))
    end
  end

  def submit_button(form, label, options = {})
    content_tag(:div, class: 'btn-group') do
      form.button(label, options.merge(class: 'btn btn-primary', data: { disable_with: label }))
    end
  end

  def cancel_link(url)
    link_to(ti(:"button.cancel"), url, class: 'link cancel')
  end

  def spinner
    image_tag('spinner.gif', size: '16x16', class: 'spinner', style: 'display: none;')
  end

  private

  # Get the cancel url for the given object considering options:
  # 1. Use :cancel_url_new or :cancel_url_edit option, if present
  # 2. Use :cancel_url option, if present
  # 3. Use polymorphic_path(object)
  def get_cancel_url(object, options)
    if params[:return_url].present?
      url = URI.parse(params[:return_url]).path rescue nil
      return url if url
    end

    record = Array(object).last
    cancel_url = options.delete(:cancel_url)
    cancel_url_new = options.delete(:cancel_url_new)
    cancel_url_edit = options.delete(:cancel_url_edit)
    url = record.new_record? ? cancel_url_new : cancel_url_edit
    url || cancel_url || polymorphic_path(object)
  end

end
