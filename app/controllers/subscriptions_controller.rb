# encoding: utf-8
class SubscriptionsController < CrudController
  
  include RenderPeoplePdf

  self.nesting = Group, MailingList
  
  decorates :group
  
  prepend_before_filter :parent
  
  alias_method :mailing_list, :parent


  def index
    respond_to do |format|
      format.html { load_instance_variables }
      format.pdf  { render_pdf(mailing_list.people) }
      format.csv  { render_csv(mailing_list.people) }
    end
  end
  
  private
  
  def authorize_class
    authorize!(:index_subscriptions, mailing_list)
  end

  def load_instance_variables
    @group_subs = group_subscriptions
    @person_subs = person_subscriptions
    @event_subs = event_subscriptions
    @excluded_person_subs = person_subscriptions(true)
  end

  def render_csv(people)
    csv = Export::CsvPeople.export_address(people)
    send_data csv, type: :csv
  end

  def group_subscriptions
    subscriptions_for_type(Group).
      includes(:related_role_types).
      order('groups.name')
  end

  def person_subscriptions(excluded = false)
    subscriptions_for_type(Person).
      where(excluded: excluded).
      order('people.last_name', 'people.first_name')
  end

  def event_subscriptions
    subscriptions_for_type(Event).order('events.name')
  end
  
  def subscriptions_for_type(klass)
    mailing_list.subscriptions.
      where(subscriber_type: klass.name).
      joins("INNER JOIN #{klass.table_name} ON #{klass.table_name}.id = subscriptions.subscriber_id").
      includes(:subscriber, :mailing_list)
  end

end
