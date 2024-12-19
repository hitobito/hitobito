
module MultiselectHelper
  # Render
  def extended_all_checkbox(total_count)
    content_tag(:label, class: "extended_all btn btn-link") do
      check_box_tag(:extended_all, total_count, false, class: 'd-none') +
        content_tag(:span, t('global.extended_select_all', count: total_count))
    end
  end
end
