# encoding: utf-8

#  Copyright (c) 2014-2017, insime Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module TarantulaConfig

  def crawl_as(person)
    person.password = "foobar"
    person.save!
    post "/users/sign_in", person: { email: person.email, password: "foobar" }
    follow_redirect!

    t = tarantula_crawler(self)
    # t.handlers << Relevance::Tarantula::TidyHandler.new

    configure_urls(t, person)

    t.crawl_timeout = 20.minutes
    t.crawl
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/LineLength
  def configure_urls(t, person)
    # some links use example.com as a domain, allow them
    t.skip_uri_patterns.delete(/^http/)
    t.skip_uri_patterns << /^http(?!:\/\/www\.example\.com)/
    # only test two languages (de and fr), the rest should be the same
    t.skip_uri_patterns << /\/(it)|(en)\//
    t.skip_uri_patterns << /year=#{outside_three_years_window}/
    t.skip_uri_patterns << /users\/sign_out/
    # sphinx not running
    t.skip_uri_patterns << /\/full$/
    # no modifications of user roles (and thereof its permissions)
    group_roles = person.roles.collect(&:id).join("|")
    t.skip_uri_patterns << /groups\/\d+\/roles\/(#{group_roles})$/
    # no ajax links in application market
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/application_market\/\d+\/participant$/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/application_market\/\d+\/waiting_list$/
    # not too many csv, email and pdf requests due to different sorting
    t.skip_uri_patterns << /groups\/\d+\/people\?.*kind.*sort/
    t.skip_uri_patterns << /groups\/\d+\/people\.csv\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/people\.email\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/people\.pdf\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\?.*filter.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.csv\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.email\?.*sort/
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/participations\.pdf\?.*sort/
    # do not change role type for own event roles
    event_roles = person.event_roles.pluck(:id).join("|")
    t.skip_uri_patterns << /groups\/\d+\/events\/\d+\/roles\/(#{event_roles})$/
    # custom return_urls end up like that.
    t.skip_uri_patterns << /\:3000\-?\d+$/
    # avoid impersionation as results in 401s
    t.skip_uri_patterns << /groups\/\d+\/people\/\d+\/impersonate$/

    # The parent entry may already have been deleted, thus producing 404s.
    t.allow_404_for(/groups$/)
    t.allow_404_for(/groups\/\d+\/notes\/\d+$/)
    t.allow_404_for(/groups\/\d+\/roles$/)
    t.allow_404_for(/groups\/\d+\/roles\/\d+$/)
    t.allow_404_for(/groups\/\d+\/people$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/edit/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/qualifications\/\d+$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/colleagues$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/log$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/history$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/invoices$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/tags\?name=-?\d+$/)
    t.allow_500_for(/groups\/\d+\/people\/\d+\/tags\?name=-?\d+$/)
    t.allow_404_for(/groups\/\d+\/people\/\d+\/notes\/\d+$/)
    t.allow_500_for(/groups\/\d+\/people\/\d+\/notes\/\d+$/)
    t.allow_500_for(/groups\/\d+\/people\/\d+\/send_password_instructions$/) # we might have switched to another account
    t.allow_404_for(/groups\/\d+\/merge$/)
    t.allow_404_for(/groups\/\d+\/move$/)
    t.allow_404_for(/groups\/\d+\/events$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/roles$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/roles\/\d+$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/participations\/\d+$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/qualifications$/)
    t.allow_404_for(/groups\/\d+\/events\/\d+\/qualifications\/\d+$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/user$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/person$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/event$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/exclude_person$/)
    t.allow_404_for(/groups\/\d+\/mailing_lists\/\d+\/subscriptions\/\d+$/)
    t.allow_404_for(/groups\/\d+\/invoice_articles\/\d+$/)
    t.allow_404_for(/event_kinds\/\d+$/)
    t.allow_404_for(/event_kinds$/)
    # tarantula role type is invalid
    t.allow_404_for(/groups\/\d+\/events\/\d+\/participations$/)
    # kind already deleted in another language
    t.allow_404_for(/qualification_kinds\/\d+$/)
    # label format already deleted in another language
    t.allow_404_for(/label_formats\/\d+$/)
    # groups already deleted in another language
    t.allow_404_for(/fr\/groups\/\d+$/)
    # custom return_urls end up like that.
    t.allow_404_for(/^\-?\d+$/)
    t.allow_500_for(/^\-?\d+$/)
    # delete qualification is not allowed after role was removed from person
    t.allow_500_for(/groups\/\d+\/people\/\d+\/qualifications\/\d+$/)
    # switching language when creating an own participation failed will result in an
    # access denied - POST participations is allowed, but not GET participations
    # (only GET participations/new).
    t.allow_500_for(/groups\/\d+\/events\/\d+\/participations\?event_participation/)
    # tarantula posts number instead of filename which causes a 500 error
    t.allow_500_for(/groups\/\d+\/events\/\d+\/attachments/)
  end
  # rubocop:enable Metrics/MethodLength, Style/RegexpLiteral, Metrics/AbcSize

  # Creates a regexp that only allows the last, current and next year
  def outside_three_years_window
    year = Time.zone.today.year
    [year - 1, year, year + 1].collect do |d|
      "(?!#{d})"
    end.join
  end
end
