module AssignmentsHelper
  def attachment_link_to(attachment)
    case attachment
    when Message::Letter
      link_to(t("assignments.attachment"),
        group_mailing_list_message_path(attachment.group,
          attachment.mailing_list,
          attachment,
          format: :pdf))
    end
  end
end
