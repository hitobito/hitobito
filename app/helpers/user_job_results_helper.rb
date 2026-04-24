#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module UserJobResultsHelper
  def job_status_icon(user_job_result)
    icon_names_by_status = {
      planned: "circle-notch",
      in_progress: "spinner",
      success: "circle-check",
      error: "circle-xmark"
    }

    icon_name = icon_names_by_status[user_job_result.status.to_sym]
    icon_options = {filled: true, "data-bs-toggle": "tooltip", title: user_job_result.status_label}
    icon_options[:class] = "fa-spin-pulse" if user_job_result.in_progress?

    icon(icon_name, icon_options)
  end

  def job_progress_bar(progress)
    content_tag(
      :div, nil, class: "progress", role: "progressbar",
      "aria-valuenow": progress, "aria-valuemin": "0", "aria-valuemax": "100"
    ) do
      content_tag(:div, "#{progress}%", class: "progress-bar", style: "width: #{progress}%")
    end
  end

  def job_timestamp(timestamp)
    return "-" unless timestamp

    I18n.l(timestamp, format: :date_time)
  end
end
