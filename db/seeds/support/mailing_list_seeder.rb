class MailingListSeeder

  def seed_mailing_list(group_id)
    mailing_list = MailingList.seed do |m|
      m.name = Faker::Superhero.name
      m.mail_name = Faker::Internet.user_name + Faker::Number.number(5)
      m.group_id = group_id
    end.first
    seed_messages(mailing_list)
  end

  private

  def seed_messages(mailing_list)
    rand(10).times do
      Messages::TextMessage.seed do |m|
        m.recipients_source = mailing_list
        m.subject = Faker::Book.title
        m.body = Faker::Lorem.sentence(2)
        m.updated_at = Faker::Time.between(DateTime.now - 10.months, DateTime.now)
      end
    end

    rand(11).times do
      message = Messages::BulkMail.seed do |m|
        m.recipients_source = mailing_list
        m.subject = Faker::Book.title
        m.updated_at = Faker::Time.between(DateTime.now - 10.months, DateTime.now) 
      end.first
      seed_mail_log(message)
    end
  end

  def seed_mail_log(message)
    MailLog.seed do |m|
      m.message = message
      m.mail_from = Faker::Internet.email
      m.mail_hash = Digest::MD5.new.hexdigest(Faker::Lorem.characters(200))
      m.status = MailLog.statuses.to_a.sample.first
      m.updated_at = Faker::Time.between(DateTime.now - 3.months, DateTime.now) 
    end
  end

end
