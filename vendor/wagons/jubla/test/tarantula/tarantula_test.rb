require "test_helper"
require "relevance/tarantula"

class TarantulaTest < ActionController::IntegrationTest
  # Load enough test data to ensure that there's a link to every page in your
  # application. Doing so allows Tarantula to follow those links and crawl
  # every page.  For many applications, you can load a decent data set by
  # loading all fixtures.

  self.reset_fixture_path File.expand_path("../../../spec/fixtures", __FILE__)


  def test_tarantula_as_federal_board_member
    crawl_as(people(:top_leader))
  end

  def test_tarantula_as_flock_leader
    crawl_as(people(:flock_leader_bern))
  end

  def test_tarantula_as_child
    crawl_as(people(:child))
  end

  def crawl_as(person)
    person.password = 'foobar'
    person.save!
    post '/users/sign_in', person: {email: person.email, password: 'foobar'}
    follow_redirect!

    t = tarantula_crawler(self)
    #t.handlers << Relevance::Tarantula::TidyHandler.new
    t.skip_uri_patterns << /year=201[04-9]/
    t.skip_uri_patterns << /year=200[0-9]/
    t.skip_uri_patterns << /year=202[0-9]/
    t.skip_uri_patterns << /users\/sign_out/
    # no modifications of user roles (and thereof its permissions)
    t.skip_uri_patterns << /groups\/\d+\/roles\/(#{person.roles.collect(&:id).join("|")})$/

    # The type or merge_group_id tarantula generates is not from the
    # given selection, thus producing 404s.
    t.allow_404_for /groups$/
    t.allow_404_for /groups\/\d+\/roles$/
    t.allow_404_for /groups\/\d+\/roles\/\d+$/
    t.allow_404_for /groups\/\d+\/people$/
    t.allow_404_for /groups\/\d+\/merge$/
    t.allow_404_for /groups\/\d+\/move$/
    t.allow_404_for /groups\/\d+\/events$/
    t.allow_404_for /groups\/\d+\/events\/\d+$/
    t.allow_404_for /groups\/\d+\/events\/\d+\/roles$/
    t.allow_404_for /groups\/\d+\/events\/\d+\/roles\/\d+$/
    t.allow_404_for /groups\/\d+\/mailing_lists\/\d+\/subscriptions\/person$/
    t.allow_404_for /groups\/\d+\/mailing_lists\/\d+\/subscriptions\/event$/
    t.allow_404_for /groups\/\d+\/mailing_lists\/\d+\/subscriptions\/exclude_person$/
    t.allow_404_for /groups\/\d+\/mailing_lists\/\d+\/subscriptions\/\d+$/
    t.allow_404_for /event_kinds\/\d+$/
    t.allow_404_for /event_kinds$/
    t.allow_404_for /groups\/\d+\/member_counts$/
    # custom return_urls end up like that.
    t.allow_404_for /^\-?\d+$/

    # sphinx not running
    t.allow_500_for /full$/
    # delete qualification is not allowed after role was removed from person
    t.allow_500_for /groups\/\d+\/people\/\d+\/qualifications\/\d+$/

    t.crawl_timeout = 5.minutes
    t.crawl
  end
end
