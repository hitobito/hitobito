class Event::ParticipationMailer < ActionMailer::Base

  helper_method :partcipation_url, :event_details

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   de.event.participation_mailer.created.subject
  #
  def confirmation(participation)
    @participation = participation
    @person = participation.person
    @event = participation.event
    mail to: @person.email
  end
  
  def approval(participation, recipients)
    @participation = participation
    @person = participation.person
    @event = participation.event
    mail to: recipients
  end

  private
  
  def partcipation_url
    event_participation_url(@event, @participation)
  end

  def event_details
    EventPresenter.new.present(@event)
  end

  ## Helper class for presenting event infos
  class EventPresenter
    PADDING = 15
    attr_reader :event

    def present(event)
      @event =  event
      prepare_info.map do |key, value| 
        value if value.present?
      end.compact.join("\n")
    end

    private
    def prepare_info
      event_info = {}
      event_info[:name] = padded(:name)
      event_info[:contact] = padded(:contact) { |event| "#{event.contact} (#{event.contact.email})" }
      event_info[:location] = padded(:location) { |event| pad_array(event.location.split("\n")) } 
      event_info[:dates] = padded(:dates) { |event|  pad_array(event.dates.map(&:to_s)) } 
      event_info
    end

    def pad_array(parts)
      first = parts.shift
      rest = parts.map {|part| "".ljust(PADDING + 1) + part }
      [first, rest].join("\n").strip
    end

    def padded(key) 
      if @event.send(key).present?
        label = label_for(key)
        value = block_given? ? "#{yield(event)}" : @event.send(key)
        "#{label} #{value}" if value
      end
    end

    def label_for(key)
      "#{Event.human_attribute_name(key)}:".ljust(PADDING)
    end

  end

end
