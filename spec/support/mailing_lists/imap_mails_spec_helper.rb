# frozen_string_literal: true

module MailingLists::ImapMailsSpecHelper

  def built_imap_mail(plain_body: true)
    Imap::Mail.build(imap_fetch_data(plain_body: plain_body))
  end

  def imap_fetch_data(plain_body: true)
    fetch_data_id = plain_body ? 1 : 2
    Net::IMAP::FetchData.new(fetch_data_id, mail_attrs(plain_body))
  end

  private

  def plain_text_mail
    Mail.new do
      from    'from@example.com'
      to      'to@example.com'
      subject 'Testflight from 24.4.2021'
      body    'SpaceX rocks!'
    end
  end

  def multipart_mail
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

  def mail_attrs(plain_body)
    mail = plain_body ? plain_text_mail : multipart_mail

    {
      'UID' => plain_body ? '42' : '43',
      'RFC822' => mail.to_s,
      'ENVELOPE' => new_envelope,
      'BODYSTRUCTURE' => plain_body ? text_body : html_body,
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
      "#{name}.com"
    )
  end

  def text_body
    Net::IMAP::BodyTypeText.new('TEXT')
  end

  def html_body
    Net::IMAP::BodyTypeMultipart.new('MULTIPART')
  end
end
