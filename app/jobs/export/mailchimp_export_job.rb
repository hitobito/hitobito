class Export::MailchimpExportJob < BaseJob
  def initialize group_id
    super()
    @group = Group.find(params[:group_id])
    @people = @group.people
    @list_id = @group.mailchimp_list_id

    @gibbon = Gibbon::Request.new(api_key: @group.mailchimp_api_key)
    @existing_subscribers = @gibbon.lists(@list_id).members.retrieve.body["members"]
  end

  def perform
    subscribe_people_in_the_group
    unsubscribe_people_not_in_the_group
  end

  private

  def subscribe_people_in_the_group
    @gibbon.batches.create(body: {
      operations: subscribing_operations
    })
  end

  def unsubscribe_people_not_in_the_group
    @gibbon.batches.create(body: {
      operations: unsubscribing_operations
    })
  end

  def subscribing_operations
    people_to_be_subscribed.map do |person|
      {
        method: "POST",
        path: "lists/#{@list_id}/members",
        body: {
          email_address: person.email,
          status: "subscribed",
          merge_fields: {
            FNAME: person.first_name,
            LNAME: person.last_name
          }
        }.to_json
      }
    end
  end

  def unsubscribing_operations
    people_to_be_unsubscribed.map do |person|
      {
        method: "DELETE",
        path: "lists/#{@list_id}/members/#{subscriber_hash person["email_address"]}",
      }
    end
  end

  def people_to_be_subscribed
    @people.select do |person|
      !existing_subscribers_email_addresses.include? person.email
    end
  end

  def people_to_be_unsubscribed
    @existing_subscribers.select do |subscriber|
      !@people.map(&:email).include? subscriber["email_address"]
    end
  end

  def existing_subscribers_email_addresses
    @existing_subscribers.map{|subscriber| subscriber["email_address"]}
  end

  def subscriber_hash email
    Digest::MD5.hexdigest email.downcase
  end
end
