require 'spec_helper'
require 'digest/md5'

describe Synchronize::Mailchimp::Synchronizator do
  let(:user)  { people(:top_leader) }
  let(:mailing_list) { mailing_lists(:leaders) }

  subject { Synchronize::Mailchimp::Synchronizator.new(mailing_list) }

  before :each do
    mailing_list.update!(mailchimp_list_id: 123456789,
                         mailchimp_api_key: '1234567890d66d25cc5c9285ab5a5552-us12')
    stub_requests
  end

  describe "initialization" do
    it "assigns the mailing list to an instance variable." do
      expect(subject.instance_variable_get(:@mailing_list)).to eq mailing_list
    end

    it "instantiates a new Gibbon instance." do
      expect(subject.instance_variable_get(:@gibbon).class).to eq Gibbon::Request
    end

    it "assigns people on the hitobito's mailing list to an instance variable." do
      expect(subject.instance_variable_get(:@people_on_the_list)).to eq mailing_list.people
    end

    it "assigns people on the mailchimp list to an instance variable." do
      expect(subject.instance_variable_get(:@people_on_the_mailchimp_list).map{|person| person["email_address"]}).to eq(["mat@zeilenwerk.ch", "graf_lenny@hitobito.example.com"])
    end
  end

  describe "private methods" do
    before do
      mailing_list.subscriptions.create!(subscriber: user)
    end
    it "prepares subscribing operations." do
      expect(subject.send(:subscribing_operations)).to eq [{
            method: "POST",
            path: "lists/#{mailing_list.mailchimp_list_id}/members",
            body: {
              email_address: mailing_list.people.first.email,
              status: "subscribed",
              merge_fields: {
                FNAME: mailing_list.people.first.first_name,
                LNAME: mailing_list.people.first.last_name
              }
            }.to_json
      }]
    end

    it "prepares deleting operations." do
      expect(subject.send(:deleting_operations)).to eq [{ method: "DELETE",
                                                          path: "lists/#{mailing_list.mailchimp_list_id}/members/#{Digest::MD5.hexdigest("mat@zeilenwerk.ch")}"},
                                                        { method: "DELETE",
                                                          path: "lists/#{mailing_list.mailchimp_list_id}/members/#{Digest::MD5.hexdigest("graf_lenny@hitobito.example.com")}"}]
    end

    it "filter people to be subscribed." do
      expect(subject.send(:people_to_be_subscribed).count).to eq 1
      expect(subject.send(:people_to_be_subscribed).first.email).to eq mailing_list.people.first.email
    end

    it "filter people to be deleted." do
      expect(subject.send(:people_to_be_deleted).map{|p| p["email_address"]}).to eq ["mat@zeilenwerk.ch", "graf_lenny@hitobito.example.com"]
    end

    it "hash an email address." do
      hashed_email = Digest::MD5.hexdigest(user.email)
      expect(subject.send(:subscriber_hash, user.email)).to eq hashed_email
    end
  end

  def stub_requests
    stub_request(:get, "https://us12.api.mailchimp.com/3.0/lists/123456789/members?count=1000000").
      with(headers: {'Accept'=>'*/*',
                     'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                     'Authorization'=>'Basic YXBpa2V5OjEyMzQ1Njc4OTBkNjZkMjVjYzVjOTI4NWFiNWE1NTUyLXVzMTI=',
                     'Content-Type'=>'application/json',
                     'User-Agent'=>'Faraday v0.15.3'}).
                     to_return(status: 200, body: {"members"=>
                                                   [{"id"=>"e8b203bbb7be4635c192cfb67cf82273",
                                                     "email_address"=>"mat@zeilenwerk.ch",
                                                     "unique_email_id"=>"eb8653831f",
                                                     "email_type"=>"html",
                                                     "status"=>"subscribed",
                                                     "merge_fields"=>{"FNAME"=>"Mat", "LNAME"=>"Lukasik", "ADDRESS"=>"", "PHONE"=>"", "BIRTHDAY"=>""},
                                                     "stats"=>{"avg_open_rate"=>0, "avg_click_rate"=>0},
                                                     "ip_signup"=>"",
                                                     "timestamp_signup"=>"",
                                                     "ip_opt"=>"",
                                                     "timestamp_opt"=>"2018-07-05T07:02:26+00:00",
                                                     "member_rating"=>2,
                                                     "last_changed"=>"2018-07-05T07:02:26+00:00",
                                                     "language"=>"",
                                                     "vip"=>false,
                                                     "email_client"=>"",
                                                     "location"=>{"latitude"=>0, "longitude"=>0, "gmtoff"=>0, "dstoff"=>0, "country_code"=>"", "timezone"=>""},
                                                     "list_id"=>"a7d7080b0f",
                                                     "_links"=>
                                                   [{"rel"=>"self",
                                                     "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273",
                                                     "method"=>"GET",
                                                     "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json"},
                                                     {"rel"=>"parent",
                                                      "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                                                      "method"=>"GET",
                                                      "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json",
                                                      "schema"=>"https://us12.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json"},
                                                      {"rel"=>"update",
                                                       "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273",
                                                       "method"=>"PATCH",
                                                       "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                                                       "schema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PATCH.json"},
                                                       {"rel"=>"upsert",
                                                        "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273",
                                                        "method"=>"PUT",
                                                        "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                                                        "schema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PUT.json"},
                                                        {"rel"=>"delete", "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273", "method"=>"DELETE"},
                                                        {"rel"=>"activity",
                                                         "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273/activity",
                                                         "method"=>"GET",
                                                         "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Activity/Response.json"},
                                                         {"rel"=>"goals",
                                                          "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273/goals",
                                                          "method"=>"GET",
                                                          "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Goals/Response.json"},
                                                          {"rel"=>"notes",
                                                           "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273/notes",
                                                           "method"=>"GET",
                                                           "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Notes/CollectionResponse.json"},
                                                           {"rel"=>"delete_permanent",
                                                            "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/e8b203bbb7be4635c192cfb67cf82273/actions/delete-permanent",
                                                            "method"=>"POST"}]},
                                                            {"id"=>"b4341541b9ba9f625f5d979c5b5e6039",
                                                             "email_address"=>"graf_lenny@hitobito.example.com",
                                                             "unique_email_id"=>"e978b6b995",
                                                             "email_type"=>"html",
                                                             "status"=>"subscribed",
                                                             "merge_fields"=>{"FNAME"=>"Lenny", "LNAME"=>"Graf", "ADDRESS"=>"", "PHONE"=>"", "BIRTHDAY"=>""},
                                                             "stats"=>{"avg_open_rate"=>0, "avg_click_rate"=>0},
                                                             "ip_signup"=>"",
                                                             "timestamp_signup"=>"",
                                                             "ip_opt"=>"",
                                                             "timestamp_opt"=>"2018-07-05T07:02:25+00:00",
                                                             "member_rating"=>2,
                                                             "last_changed"=>"2018-07-05T07:02:26+00:00",
                                                             "language"=>"",
                                                             "vip"=>false,
                                                             "email_client"=>"",
                                                             "location"=>{"latitude"=>0, "longitude"=>0, "gmtoff"=>0, "dstoff"=>0, "country_code"=>"", "timezone"=>""},
                                                             "list_id"=>"a7d7080b0f",
                                                             "_links"=>
                                                   [{"rel"=>"self",
                                                     "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039",
                                                     "method"=>"GET",
                                                     "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json"},
                                                     {"rel"=>"parent",
                                                      "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                                                      "method"=>"GET",
                                                      "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json",
                                                      "schema"=>"https://us12.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json"},
                                                      {"rel"=>"update",
                                                       "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039",
                                                       "method"=>"PATCH",
                                                       "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                                                       "schema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PATCH.json"},
                                                       {"rel"=>"upsert",
                                                        "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039",
                                                        "method"=>"PUT",
                                                        "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                                                        "schema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/PUT.json"},
                                                        {"rel"=>"delete", "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039", "method"=>"DELETE"},
                                                        {"rel"=>"activity",
                                                         "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039/activity",
                                                         "method"=>"GET",
                                                         "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Activity/Response.json"},
                                                         {"rel"=>"goals",
                                                          "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039/goals",
                                                          "method"=>"GET",
                                                          "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Goals/Response.json"},
                                                          {"rel"=>"notes",
                                                           "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039/notes",
                                                           "method"=>"GET",
                                                           "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Notes/CollectionResponse.json"},
                                                           {"rel"=>"delete_permanent",
                                                            "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members/b4341541b9ba9f625f5d979c5b5e6039/actions/delete-permanent",
                                                            "method"=>"POST"}]}],
                                                            "list_id"=>"a7d7080b0f",
                                                            "total_items"=>2,
                                                            "_links"=>
                                                   [{"rel"=>"self",
                                                     "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                                                     "method"=>"GET",
                                                     "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/CollectionResponse.json",
                                                     "schema"=>"https://us12.api.mailchimp.com/schema/3.0/CollectionLinks/Lists/Members.json"},
                                                     {"rel"=>"parent",
                                                      "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f",
                                                      "method"=>"GET",
                                                      "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json"},
                                                      {"rel"=>"create",
                                                       "href"=>"https://us12.api.mailchimp.com/3.0/lists/a7d7080b0f/members",
                                                       "method"=>"POST",
                                                       "targetSchema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/Response.json",
                                                       "schema"=>"https://us12.api.mailchimp.com/schema/3.0/Definitions/Lists/Members/POST.json"}]}.to_json,
                                                       headers: {})
  end

end
