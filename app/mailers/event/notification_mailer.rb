class Event::NotificationMailer < ApplicationMailer
    def event_notification(emails, subject, body, cc: [])
        @body = body

        mail(
            to: emails,
            cc: cc,
            subject: subject
        ) do |format|
            format.html { render html: @body.html_safe }
        end
    end
end