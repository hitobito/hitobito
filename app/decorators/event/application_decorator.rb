#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApplicationDecorator < ::ApplicationDecorator
  decorates "event/application"

  decorates_association :event, with: EventDecorator
  decorates_association :priority_1, with: EventDecorator
  decorates_association :priority_2, with: EventDecorator
  decorates_association :priority_3, with: EventDecorator

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link(group = nil)
    group ||= event.groups.first
    event.labeled_link(h.group_event_participation_path(group, event, participation),
      can?(:show, participation))
  end

  def contact
    c = model.contact
    c ? "#{c.class.base_class.name}Decorator".constantize.decorate(c) : nil
  end

  def priorities?
    event.priorization? || priority_2_id || waiting_list?
  end

  def priority(event)
    prio = model.priority(event)
    prio = if prio
      "Prio #{prio}"
    else
      waiting_list? ? "Warteliste" : nil
    end
    content_tag(:span, prio, class: "badge badge-info") if prio
  end

  def precondition_warnings(event)
    if event.supports_applications && event.course_kind?
      checker = Event::PreconditionChecker.new(event, participation.person)
      h.badge("!", "warning", checker.errors_text.flatten.join("<br>")) unless checker.valid?
    end
  end

  def approval_badge
    h.badge(*approval_fields(approved?, rejected?))
  end

  def approval_label
    label, type, desc = approval_fields(approved?, rejected?)
    h.badge(label, type) + " ".html_safe + desc
  end

  def approval_fields(approved, rejected)
    if approved
      ["&#x2713;".html_safe, "success", translate("approval.approved")]
    elsif rejected
      ["&#x00D7;".html_safe, "important", translate("approval.rejected")]
    else
      ["?", "warning", translate("approval.missing")]
    end
  end
end
