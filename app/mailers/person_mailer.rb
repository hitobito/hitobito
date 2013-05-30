class PersonMailer < ActionMailer::Base

  CONTENT_LOGIN = 'send_login'

  def login(recipient, sender)
    content = CustomContent.get(CONTENT_LOGIN)
    values = {
      'recipient-name' => recipient.greeting_name,
      'sender-name'    => sender.to_s,
      'login-url'      => "<a href=\"#{login_url(recipient)}\">#{login_url(recipient)}</a>"
    }

    mail(to: recipient.email,
         return_path: return_path(sender),
         sender: return_path(sender),
         reply_to: sender.email,
         subject: content.subject) do |format|
      format.html { render text: content.body_with_values(values) }
    end
  end

  private

  def login_url(person)
    edit_person_password_url(person, reset_password_token: person.reset_password_token)
  end

  def return_path(sender)
    app_sender = Settings.email.sender
    app_sender_name = app_sender[/^.*<(.+)@.+\..+>$/, 1] || app_sender[/^(.+)@.+\..+$/, 1] || 'noreply'

    MailRelay::Lists.personal_return_path(app_sender_name, sender.email)
  end

end
