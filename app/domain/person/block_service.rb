class Person::BlockService
  def initialize(person, current_user: nil)
    @person = person
    @current_user = current_user
  end

  def block!
    @person.update!(blocked_at: Time.zone.now) && log(:block_person)
    true
  end

  def unblock!
    @person.update!(blocked_at: nil, inactivity_block_warning_sent_at: nil) && log(:unblock_person)
    true
  end

  def inactivity_warning!
    Person::InactivityBlockMailer.inactivity_block_warning(@person).deliver &&
      @person.update!(inactivity_block_warning_sent_at: Time.zone.now)
  end

  def self.warn_after
    Settings.inactivity_block&.warn_after&.to_i&.seconds
  end

  def self.block_after
    Settings.inactivity_block&.block_after&.to_i&.seconds
  end

  def self.warn?
    warn_after.present? && warn_after.positive?
  end

  def self.block?
    block_after.present? && block_after.positive?
  end

  protected

  def log(event)
    PaperTrail::Version.create(main: @person, item: @person, whodunnit: @current_user, event: event)
  end
end
