require 'spec_helper'

describe MailRelay::AddressList do

  it 'contains main and additional mailing emails' do
    e1 = Fabricate(:additional_email, contactable: people(:top_leader), mailings: true)
    Fabricate(:additional_email, contactable: people(:bottom_member), mailings: false)
    expect(entries).to match_array([
      'bottom_member@example.com',
      'hitobito@puzzle.ch',
      'top_leader@example.com',
      e1.email
    ])
  end

  it 'does not contain blank emails' do
    people(:bottom_member).update_attributes!(email: ' ')
    expect(entries).to match_array([
      'hitobito@puzzle.ch',
      'top_leader@example.com'
    ])
  end

  def entries(labels = [] )
    described_class.new(Person.all, labels).entries
  end
end
