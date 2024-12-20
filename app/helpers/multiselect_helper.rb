
module MultiselectHelper
  # Render
  def extended_all_checkbox(ids)
    content_tag(:label, class: "extended_all btn btn-link") do
      check_box_tag(:extended_all, ids.count, false, data: { ids: JSON.generate(ids) }, class: 'd-none') +
        content_tag(:span, t('global.extended_select_all', count: ids.count))
    end
  end
end
