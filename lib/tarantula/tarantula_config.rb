# encoding: utf-8

#  Copyright (c) 2014, insime Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TarantulaConfig

  def crawl_as(person)
    person.password = 'foobar'
    person.save!
    post '/users/sign_in', person: { email: person.email, password: 'foobar' }
    follow_redirect!

    t = tarantula_crawler(self)
    # t.handlers << Relevance::Tarantula::TidyHandler.new

    configure_urls(t, person)

    t.crawl_timeout = 20.minutes
    t.crawl
  end

  # rubocop:disable MethodLength
  def configure_urls(t, person)
    # some links use example.com as a domain, allow them
    t.skip_uri_patterns.delete(/^http/)
    t.skip_uri_patterns << /^http(?!:\/\/www\.example\.com)/
    t.skip_uri_patterns << /year=#{outside_three_years_window}/
    t.skip_uri_patterns << /users\/sign_out/
    # sphinx not running
    t.skip_uri_patterns << /\/full$/
    # no modifications of user roles (and thereof its permissions)
    t.skip_uri_patterns << /groups\/\d+\/roles\/(#{person.roles.collect(&:id).join("|")})$/
    # no ajax links in application market
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/application_market\/\d+\/participant$/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/application_market\/\d+\/waiting_list$/
    # not too many csv, email and pdf requests due to different sorting
    t.skip_uri_patterns << /groups\/\d+\/people\.csv\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/people\.email\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/people\.pdf\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.csv\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.email\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.pdf\?.*sort/

    # The parent entry may already have been deleted, thus producing 404s.
    t.allow_404_for(/groups$/)
    t.allow_404_for(/groups\/\d+\/roles$/)
    t.allow_404_for(/groups\/\d+\/roles\/\d+$/)
    t.allow_404_for(/groups\/\d+\/people$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/qualifications\/\d+$/)
    t.allow_404_for(/groups\/\d+\/merge$/)
    t.allow_404_for(/groups\/\d+\/move$/)
    t.allow_404_for(/groups\/\d+\/events$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/roles$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/roles\/\d+$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/participations\/\d+$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/person$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/event$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/exclude_person$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/\d+$/)
    t.allow_404_for(/event_kinds\/\d+$/)
    t.allow_404_for(/event_kinds$/)
    # kind already deleted in another language
    t.allow_404_for(/qualification_kinds\/\d+$/)
    # groups already deleted in another language
    t.allow_404_for(/it\/groups\/\d+$/)
    # custom return_urls end up like that.
    t.allow_404_for(/^\-?\d+$/)

    # delete qualification is not allowed after role was removed from person
    t.allow_500_for(/groups\/\d+\/people\/\d+\/qualifications\/\d+$/)
  end
  # rubocop:enable MethodLength

  # Creates a regexp that only allows the last, current and next year
  def outside_three_years_window
    year = Date.today.year
    [year - 1, year, year + 1].collect do |d|
      "(?!#{d})"
    end.join
  end
end
