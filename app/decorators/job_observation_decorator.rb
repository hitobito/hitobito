#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class JobObservationDecorator < ApplicationDecorator
  def attempts_of_max_attempts
    "#{attempts}/#{max_attempts}"
  end

  def formatted_started_at
    format_timestamp(started_at)
  end

  def formatted_finished_at
    format_timestamp(finished_at)
  end

  def progress_bar
    h.content_tag(
      :div, nil, class: "progress", role: "progressbar",
      "aria-valuenow": progress, "aria-valuemin": "0", "aria-valuemax": "100"
    ) do
      h.content_tag(:div, "#{progress}%", class: "progress-bar", style: "width: #{progress}%")
    end
  end

  def status_icon
    icon_names_by_status = {
      planned: "circle-notch",
      in_progress: "spinner",
      success: "circle-check",
      error: "circle-xmark"
    }

    icon_name = icon_names_by_status[status.to_sym]
    icon_options = {filled: true, "data-bs-toggle": "tooltip", title: status_label}
    icon_options[:class] = "fa-spin-pulse" if in_progress?

    h.icon(icon_name, icon_options)
  end

  def status_class
    h.class_names("bg-info": success?, "bg-danger": error?)
  end

  def stimulus_attributes
    stimulus_attributes = {"data-controller" => "job-observation-notification"}

    if generated_file.attached?
      stimulus_attributes["data-job-observation-notification-generated-file-download-url-value"] =
        h.download_job_observation_path(job_observation)
    end

    stimulus_attributes
  end

  private

  def format_timestamp(timestamp)
    return "-" unless timestamp

    I18n.l(timestamp, format: :date_time)
  end
end
