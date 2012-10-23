class Event::ParticipationMailer < ActionMailer::Base
  #default from: "from@example.com"
#Settings.email_sender
  helper_method :partcipation_print_url, :event_details

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.event.participation_mailer.created.subject
  #
  def confirmation(person, participation)
    @person = person
    @participation = participation
    @event = participation.event
    mail to: person.email
  end

  def partcipation_print_url
    print_event_participation_url(@event, @participation)
  end

  def event_details
    EventPresenter.new.present(@event)
  end

  private
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
      event_info[:contact] = padded(:contact) { |event| "#{event.contact} (#{event.contact.email})" }  if event.contact
      event_info[:location] = padded(:location)
      event_info[:dates] = padded(:dates) do |event| 
        dates = event.dates.map(&:to_s)
        first = dates.shift
        rest = dates.map {|date| "".ljust(PADDING + 1) + date }
        [first, rest].join("\n").strip
      end if event.dates.present?
      event_info
    end

    def padded(key)
      label = label_for(key)
      value = block_given? ? "#{yield(event)}" : @event.send(key)
      "#{label} #{value}" if value
    end

    def label_for(key)
      "#{Event.human_attribute_name(key)}:".ljust(PADDING)
    end

  end

end
