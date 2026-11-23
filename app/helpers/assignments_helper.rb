module AssignmentsHelper
  def attachment_button(attachment)
    case attachment
    when Message
      return unless attachment.mailing_list

      action_button(t("assignments.attachment"),
        group_mailing_list_message_path(entry.attachment.group,
          entry.attachment.mailing_list,
          entry.attachment),
        :paperclip)
    end
  end
end
