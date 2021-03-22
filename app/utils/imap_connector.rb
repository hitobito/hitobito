class ImapConnector

  def fetch_by_uid(uid, mailbox = 'inbox')
    perform do
      select_mailbox(mailbox)
      imap.uid_fetch(uid, attributes)[0]
    end
  end

  def move_by_uid(uid, from_mailbox, to_mailbox)
    perform do
      select_mailbox(from_mailbox)
      @imap.uid_move(uid, hash(to_mailbox))
    end
  end

  def delete_by_uid(uid, mailbox)
    perform do
      select_mailbox(mailbox)
      # imap.uid_copy(uid, 'TRASH')
      @imap.uid_store(uid, '+FLAGS', [:Deleted])
      @imap.expunge
    end
  end

  def fetch_all(mailbox)
    perform do
      select_mailbox mailbox

      mail_count = count mailbox
      mail_count.positive? ? @imap.fetch(1..mail_count, attributes) || [] : []
    end
  end

  def count(mailbox)
    select_mailbox mailbox
    @imap.status(hash(mailbox), ['MESSAGES'])['MESSAGES']
  end

  def counts
    perform do
      counts = {}
      MAILBOXES.each do |m, _|
        counts[m] = count(m)
      end
      counts
    end
  end

  private

  MAILBOXES = { inbox: 'INBOX', spam: 'Junk', failed: 'Failed' }.freeze
  # MAILBOXES = { inbox: 'INBOX', spam: 'SPAMMING', failed: 'FAILED' }.freeze

  def perform
    already_connected = @connected

    connect unless already_connected
    result = yield
    disconnect unless already_connected
    result
  end

  def connect
    @imap = Net::IMAP.new(host, 993, true)
    @imap.login(email, password)
    @connected = true
  end

  def disconnect
    unless @imap.nil?
      @imap.close
      @imap.disconnect
      @connected = false
      @selected_mailbox = nil
    end
  end

  def create_if_failed(mailbox, error)
    if (mailbox == hash(:failed)) && error.response.data.text.include?('Mailbox doesn\'t exist')
      @imap.create(hash(:failed))
      @imap.select(mailbox)
    else
      raise error
    end
  end

  def select_mailbox(mailbox)
    mailbox = hash(mailbox)

    if mailbox == @selected_mailbox
      nil
    else
      begin
        @imap.select(mailbox)
      rescue Net::IMAP::NoResponseError => e
        create_if_failed mailbox, e
      end
      @selected_mailbox = mailbox
    end
  end

  def hash(mailbox)
    unless mailbox.class == Symbol
      mailbox = mailbox.to_sym
    end

    MAILBOXES[mailbox]
  end

  def config_present?
    !Settings.email.retriever.config.nil?
  end

  def host
    return 'imap.gmail.com' unless config_present?

    Settings.email.retriever.config.address
  end

  def email
    return 'test.imap.hitobito@gmail.com' unless config_present?

    Settings.email.retriever.config.user_name
  end

  def password
    return 'test.imap' unless config_present?

    Settings.email.retriever.config.password
  end

  def attributes
    %w(ENVELOPE UID BODYSTRUCTURE BODY[TEXT] RFC822)
  end


end
