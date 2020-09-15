class MailingListSeeder

  def seed_mailing_list(group_id)
    mailing_list = MailingList.seed do |m|
      m.name = Faker::Superhero.name
      m.mail_name = Faker::Internet.user_name + Faker::Number.number(5)
      m.group_id = group_id
    end.first
    seed_mail_logs(mailing_list)
  end

  private

  def seed_mail_logs(mailing_list)
    rand(10).times do
      MailLog.seed do |m|
        m.mailing_list = mailing_list
        m.mail_from = Faker::Internet.email
        m.mail_subject = Faker::Lorem.sentence(3)
        m.mail_hash = Digest::MD5.new.hexdigest(Faker::Lorem.characters(200))
        m.status = MailLog.statuses.to_a.sample.first
        m.updated_at = Faker::Time.between(DateTime.now - 3.months, DateTime.now) 
      end
    end
  end

end
