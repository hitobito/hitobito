require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Synchronizator do
  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:mailing_list) { Fabricate(:mailing_list, group: group) }

  subject { Synchronize::Mailchimp::Synchronizator.new(mailing_list) }

  before :each do
    stub_request(:get, "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members").
      with(
        headers: {
          'Accept'=>'*/*',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'Basic YXBpa2V5OjA4MTY3NWEzYTZkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Faraday v0.15.2'
        }).
        to_return(status: 200,
                  body: %Q({
                      "members": [{
                        "id": "5e50f1734ea8bea5c0427a45cce73057",
                        "email_address": "janko@hrasko.com",
                        "unique_email_id": "bc70940af6",
                        "email_type": "html",
                        "status": "subscribed",
                        "merge_fields": {
                          "FNAME": "",
                          "LNAME": "",
                          "ADDRESS": "",
                          "PHONE": "",
                          "BIRTHDAY": ""
                        },
                        "stats": {
                          "avg_open_rate": 0,
                          "avg_click_rate": 0
                        },
                        "ip_signup": "",
                        "timestamp_signup": "",
                        "ip_opt": "178.41.92.122",
                        "timestamp_opt": "2018-07-04T04:27:29+00:00",
                        "member_rating": 2,
                        "last_changed": "2018-07-04T04:27:29+00:00",
                        "language": "",
                        "vip": false,
                        "email_client": "",
                        "location": {
                          "latitude": 0,
                          "longitude": 0,
                          "gmtoff": 0,
                          "dstoff": 0,
                          "country_code": "",
                          "timezone": ""
                        },
                        "list_id": "a7d7080b0f",
                        "_links": [{
                          "rel": "self",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057",
                          "method": "GET",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json"
                        }, {
                          "rel": "parent",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                          "method": "GET",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json",
                          "schema": "https://us12.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json"
                        }, {
                          "rel": "update",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057",
                          "method": "PATCH",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                          "schema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PATCH.json"
                        }, {
                          "rel": "upsert",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057",
                          "method": "PUT",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                          "schema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PUT.json"
                        }, {
                          "rel": "delete",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057",
                          "method": "DELETE"
                        }, {
                          "rel": "activity",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057/activity",
                          "method": "GET",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Activity/Response.json"
                        }, {
                          "rel": "goals",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057/goals",
                          "method": "GET",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Goals/Response.json"
                        }, {
                          "rel": "notes",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057/notes",
                          "method": "GET",
                          "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Notes/CollectionResponse.json"
                        }, {
                          "rel": "delete_permanent",
                          "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/5e50f1734ea8bea5c0427a45cce73057/actions/delete-permanent",
                          "method": "POST"
                        }]
                      }],
                      "list_id": "a7d7080b0f",
                      "total_items": 1,
                      "_links": [{
                        "rel": "self",
                        "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                        "method": "GET",
                        "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json",
                        "schema": "https://us12.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json"
                      }, {
                        "rel": "parent",
                        "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f",
                        "method": "GET",
                        "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json"
                      }, {
                        "rel": "create",
                        "href": "https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                        "method": "POST",
                        "targetSchema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                        "schema": "https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/POST.json"
                      }]
                    }))
  end

  describe "initialization" do
    it "assigns the mailing list to an instance variable." do
      expect(subject.instance_variable_get(:@mailing_list)).to eq mailing_list
    end

    it "instantiates a new Gibbon instance." do
      expect(subject.instance_variable_get(:@gibbon)).to_not eq nil
    end

    it "assigns people on the mailing list to an instance variable." do
      expect(subject.instance_variable_get(:@people_on_the_list)).to eq mailing_list.people
    end

    it "assigns people on the mailchimp list to an instance variable." do
      expect(subject.instance_variable_get(:@people_on_the_mailchimp_list).map{|person| person["email_address"]}).to eq(["janko@hrasko.com"])
    end
  end

  it "subscribes people to the mailchimp list that are on the mailing list."

  it "deletes people on the mailchimp list that are not on the mailing list."

  it "hashes an email address." do
    hashed_email = Digest::MD5.hexdigest(user.email)
    expect(subject.send(:subscriber_hash, user.email)).to eq hashed_email
  end
end
