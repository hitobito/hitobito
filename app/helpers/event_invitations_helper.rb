# frozen_string_literal: true

module EventInvitationsHelper
  def format_event_invitation_status(invitation)
    t("activerecord.attributes.event/invitation.statuses.#{invitation.status}")
  end
end
