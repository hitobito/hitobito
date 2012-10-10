class Event::ParticipationMailer < ActionMailer::Base
  default from: "from@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.event.participation_mailer.created.subject
  #
  def created(person, participation)
    @person = person
    @participation = participation
    @event = participation.event
    @participation_url = event_participation_path(@event, @participation)
    mail to: person.email
  end
end
