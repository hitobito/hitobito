# frozen_string_literal: true

class MailingListSeeder

  def seed_mailing_list(group_id)
    mailing_list = MailingList.seed do |m|
      m.name = Faker::Superhero.name
<<<<<<< HEAD
      m.mail_name = Faker::Internet.user_name + Faker::Number.number(5)
      m.main_email = Faker::Internet.email
=======
      m.mail_name = Faker::Internet.user_name + Faker::Number.number(5)
      m.group_id = group_id
    end.first
    seed_bulk_mail_messages(mailing_list)
  end

  private

  def seed_bulk_mail_messages(mailing_list)
    rand(10).times do
<<<<<<< HEAD
      seed_mail_log(mailing_list)
=======
      MailLog.seed do |m|
        m.mailing_list = mailing_list
        m.mail_from = Faker::Internet.email
        m.mail_subject = Faker::Lorem.sentence(3)
        m.mail_hash = Digest::MD5.new.hexdigest(Faker::Lorem.characters(200))
        m.status = MailLog.statuses.to_a.sample.first
        m.updated_at = Faker::Time.between(DateTime.now - 3.months, DateTime.now)
      end
>>>>>>> Updates syntax to accommodate new version of faker gem
    end
  end

  def seed_mail_log(mailing_list)
    updated_at = Faker::Time.between(DateTime.now - 3.months, DateTime.now)
    log_status = random_mail_log_status
    message = Message::BulkMail.new(mailing_list: mailing_list,
                                    subject: Faker::Superhero.name,
                                    state: MailLog::BULK_MESSAGE_STATUS[log_status.to_sym],
                                    sent_at: updated_at)
    MailLog.seed do |m|
      m.mail_hash = Digest::MD5.new.hexdigest(Faker::Lorem.characters(200))
      m.status = log_status
      m.mail_from = Faker::Internet.email
      m.updated_at = updated_at
      m.message = message
    end.first
  end

  def random_mail_log_status
    statuses = MailLog.statuses.to_a - [:unkown_recipient]
    statuses.sample.first
  end
end
