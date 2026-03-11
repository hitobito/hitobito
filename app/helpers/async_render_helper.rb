#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module AsyncRenderHelper
  def async_preview_placeholder(user, target_dom_id)
    stream_name = "user_#{user.id}_async_updates"

    capture do
      concat turbo_stream_from(stream_name)
      concat content_tag(:div, id: target_dom_id, class: "d-flex justify-content-center my-5") {
        content_tag(:div, class: "card shadow-sm") do
          content_tag(:div, class: "card-body text-center") do
            concat content_tag(:div, spinner(true), class: "mb-4")
            concat content_tag(:h5, t(".async_rendering_enqueued"),
              class: "text-muted fw-light mb-3")
            concat content_tag(:p, t("async_render.info_note"), class: "small text-secondary mb-0")
          end
        end
      }
    end
  end
end
