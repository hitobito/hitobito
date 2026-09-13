# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe "CardDAV endpoint", type: :request do
  let(:person) { people(:top_leader) }
  let(:token) { "carddav-token-Hei7Ohsh" }

  let(:headers) do
    {"Authorization" => ActionController::HttpAuthentication::Basic
      .encode_credentials(person.email, token)}
  end

  let(:xml_headers) { headers.merge("Content-Type" => "application/xml; charset=utf-8") }

  let(:xml) { Nokogiri::XML(response.body).remove_namespaces! }

  def hrefs = xml.xpath("//response/href").collect(&:text)

  def prop(href, name)
    xml.xpath("//response[href='#{href}']/propstat[contains(status, '200')]/prop/#{name}")
  end

  before { person.update!(carddav_token: token) }

  describe "authentication" do
    it "demands basic auth without credentials" do
      process(:propfind, "/carddav")

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match(/\ABasic realm=/)
    end

    it "names the configured application in the realm" do
      allow(Settings.application).to receive(:name).and_return("MiData")

      process(:propfind, "/carddav")

      expect(response.headers["WWW-Authenticate"]).to eq 'Basic realm="MiData"'
    end

    it "rejects an unknown token" do
      process(:propfind, "/carddav", headers: {"Authorization" =>
        ActionController::HttpAuthentication::Basic.encode_credentials("foo", "nope")})

      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts the token as basic auth password" do
      process(:propfind, "/carddav", headers: headers)

      expect(response).to have_http_status(:multi_status)
    end

    it "forbids a blocked person" do
      person.update!(blocked_at: 1.day.ago)

      process(:propfind, "/carddav", headers: headers)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a person without an email, who cannot log in" do
      person.update_columns(email: nil)

      process(:propfind, "/carddav", headers: headers)

      expect(response).to have_http_status(:forbidden)
    end

    it "forbids a person without a password, who cannot log in" do
      person.update_columns(encrypted_password: nil)

      process(:propfind, "/carddav", headers: headers)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "OPTIONS" do
    it "advertises the addressbook compliance class" do
      process(:options, "/carddav/addressbooks/people", headers: headers)

      expect(response).to have_http_status(:ok)
      expect(response.headers["DAV"]).to include("addressbook")
      expect(response.headers["Allow"]).to include("REPORT")
    end
  end

  describe "service discovery" do
    it "redirects /.well-known/carddav to the endpoint" do
      process(:propfind, "/.well-known/carddav", headers: headers)

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["Location"]).to end_with("/carddav/")
    end

    it "PROPFIND on the root points to the principal" do
      process(:propfind, "/carddav", headers: headers)

      expect(response).to have_http_status(:multi_status)
      expect(prop("/carddav/", "current-user-principal/href").text)
        .to eq "/carddav/principal/"
    end

    it "PROPFIND on the principal points to the addressbook home set" do
      process(:propfind, "/carddav/principal", headers: headers)

      expect(prop("/carddav/principal/", "addressbook-home-set/href").text)
        .to eq "/carddav/addressbooks/"
      expect(prop("/carddav/principal/", "displayname").text).to eq person.to_s
    end

    it "PROPFIND with depth 1 on the home set lists the addressbook" do
      process(:propfind, "/carddav/addressbooks", headers: headers.merge("Depth" => "1"))

      expect(hrefs).to match_array ["/carddav/addressbooks/", "/carddav/addressbooks/people/"]
    end
  end

  describe "PROPFIND on the addressbook" do
    it "reports it as an addressbook collection" do
      process(:propfind, "/carddav/addressbooks/people", headers: headers)

      expect(hrefs).to eq ["/carddav/addressbooks/people/"]
      expect(prop("/carddav/addressbooks/people/", "resourcetype/addressbook")).to be_present
      expect(prop("/carddav/addressbooks/people/", "getctag").text).to be_present
    end

    it "answers only the properties it knows" do
      body = <<~XML
        <d:propfind xmlns:d="DAV:"><d:prop><d:displayname/><d:unsupported-thing/></d:prop></d:propfind>
      XML
      process(:propfind, "/carddav/addressbooks/people", params: body, headers: xml_headers)

      expect(prop("/carddav/addressbooks/people/", "displayname")).to be_present
      expect(xml.xpath("//prop/unsupported-thing")).to be_empty
    end

    it "leaves the vcards out of a propfind for all properties" do
      process(:propfind, "/carddav/addressbooks/people",
        headers: headers.merge("Depth" => "1"))

      expect(xml.xpath("//prop/getetag")).to be_present
      expect(xml.xpath("//prop/address-data")).to be_empty
    end

    it "lists all accessible people with depth 1" do
      process(:propfind, "/carddav/addressbooks/people",
        headers: headers.merge("Depth" => "1"))

      expect(hrefs).to match_array(["/carddav/addressbooks/people/"] +
        accessible_people.collect { |p| "/carddav/addressbooks/people/#{p.id}.vcf" })
      expect(prop("/carddav/addressbooks/people/#{person.id}.vcf", "getetag").text)
        .to match(/\A".+"\z/)
    end

    it "only lists people the token owner may see" do
      person.update!(carddav_token: nil)
      other = people(:bottom_member)
      other.update!(carddav_token: token)

      process(:propfind, "/carddav/addressbooks/people",
        headers: headers.merge("Depth" => "1"))

      expect(hrefs).to match_array ["/carddav/addressbooks/people/",
        "/carddav/addressbooks/people/#{other.id}.vcf"]
    end
  end

  describe "REPORT" do
    let(:address_data) { xml.xpath("//response/propstat/prop/address-data").collect(&:text) }

    it "addressbook-query returns the vcards of all accessible people" do
      body = <<~XML
        <card:addressbook-query xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
          <d:prop><d:getetag/><card:address-data/></d:prop>
          <card:filter/>
        </card:addressbook-query>
      XML
      process(:report, "/carddav/addressbooks/people", params: body, headers: xml_headers)

      expect(response).to have_http_status(:multi_status)
      expect(hrefs).to match_array(accessible_people.collect { |p|
        "/carddav/addressbooks/people/#{p.id}.vcf"
      })
      expect(address_data.join).to include("FN:Top Leader")
    end

    it "addressbook-multiget returns only the requested vcards" do
      body = <<~XML
        <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
          <d:prop><d:getetag/><card:address-data/></d:prop>
          <d:href>/carddav/addressbooks/people/#{person.id}.vcf</d:href>
        </card:addressbook-multiget>
      XML
      process(:report, "/carddav/addressbooks/people", params: body, headers: xml_headers)

      expect(hrefs).to eq ["/carddav/addressbooks/people/#{person.id}.vcf"]
      expect(address_data.first).to include("UID:")
    end

    it "addressbook-multiget reports inaccessible hrefs as 404" do
      body = <<~XML
        <card:addressbook-multiget xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav">
          <d:prop><card:address-data/></d:prop>
          <d:href>/carddav/addressbooks/people/#{people(:root).id}.vcf</d:href>
        </card:addressbook-multiget>
      XML
      process(:report, "/carddav/addressbooks/people", params: body, headers: xml_headers)

      expect(xml.xpath("//response/status").text).to include("404")
    end
  end

  describe "GET a contact" do
    it "returns the vcard" do
      get "/carddav/addressbooks/people/#{person.id}.vcf", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "text/vcard"
      expect(response.headers["ETag"]).to match(/\A".+"\z/)
      expect(response.body).to include("FN:Top Leader")
      expect(response.body).to include("UID:")
      expect(response.body).to include("\r\n")
    end

    it "returns 404 for a person the user may not see" do
      get "/carddav/addressbooks/people/#{people(:root).id}.vcf", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  def accessible_people
    Person.accessible_by(PersonReadables.new(person))
  end
end
