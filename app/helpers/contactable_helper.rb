#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module ContactableHelper
  def contact_method_category_field(form)
    contact_method = form.object
    categories = ContactAccountCategory.for(contact_method.class.name,
      contact_method.contactable_type)

    form.collection_select(
      :category_id, categories, :id, :to_s,
      {selected: contact_method.category_id, include_blank: contact_method.new_record?}
    )
  end

  def contact_method_label_field(form)
    form.input_field(:label, placeholder: t("contactable.label_placeholder"))
  end

  def contactable_public_field_icon
    content_tag(:span, data: {bs_toggle: :tooltip},
      title: t("contactable.public_check_box.tooltip")) do
      safe_join([
        t("activerecord.attributes.social_account.public"),
        icon(:"info-circle", class: "ms-1 text-secondary")
      ], " ")
    end
  end
end
