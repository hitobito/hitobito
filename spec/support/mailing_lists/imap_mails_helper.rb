# frozen_string_literal: true

module MailingLists::ImapMailsHelper

  def new_imap_mail(text_body = true)
    fetch_data_id = text_body ? 1 : 2
    imap_mail = Net::IMAP::FetchData.new(fetch_data_id, mail_attrs(text_body))
    Imap::Mail.build(imap_mail)
  end

  def new_imap_fetch_data(text_body = true)
    fetch_data_id = text_body ? 1 : 2
    Net::IMAP::FetchData.new(fetch_data_id, mail_attrs(text_body))
  end

  private

  def new_plain_text_mail
    Mail.new do
      from    'from@example.com'
      to      'to@example.com'
      subject 'Testflight from 24.4.2021'
      body    'SpaceX rocks!'
    end
  end

  def new_multipart_mail
    Mail.new do
      from    'from@example.com'
      to      'to@example.com'
      subject 'Testflight from 24.4.2021'

      text_part do
        body 'This is just plain text!'
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<h1>This is some Html</h1>'
      end
    end
  end

  def mail_attrs(text_body)
    mail = text_body ? new_plain_text_mail : new_multipart_mail

    {
      'UID' => text_body ? '42' : '43',
      'RFC822' => mail.to_s,
      'ENVELOPE' => new_envelope,
      'BODYSTRUCTURE' => text_body ? new_text_body : new_html_body_type,
      'BODY[TEXT]' => mail.body.to_s
    }
  end

  def new_envelope
    Net::IMAP::Envelope.new(
      Time.now.to_s,
      'Testflight from 24.4.2021',
      [new_address('from')],
      [new_address('sender')],
      [new_address('reply_to')],
      [new_address('to')]
    )
  end

  def new_address(name)
    Net::IMAP::Address.new(
      name,
      nil,
      'john',
      "#{name}.example.com"
    )
  end

  def new_text_body
    Net::IMAP::BodyTypeText.new('TEXT')
  end

  def new_html_body_type
    Net::IMAP::BodyTypeMultipart.new('MULTIPART')
  end
end
