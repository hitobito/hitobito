# encoding: utf-8

#  Copyright (c) 2017, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module SearchStrategies
  class Sphinx < Base

    delegate :star_supported?, to: :class

    def query_people
      return Person.none.page(1) unless @term.present?
      query_accessible_people do |ids|
        Person.search(Riddle::Query.escape(@term),
                      per_page: QUERY_PER_PAGE,
                      star: star_supported?,
                      with: { sphinx_internal_id: ids })
      end
    end

    def query_groups
      return Group.none.page(1) unless @term.present?
      Group.search(Riddle::Query.escape(@term),
                   per_page: QUERY_PER_PAGE,
                   star: star_supported?)
    end

    def query_events
      return Event.none.page(1) unless @term.present?
      Event.search(Riddle::Query.escape(@term),
                   per_page: QUERY_PER_PAGE,
                   star: star_supported?,
                   include: :groups)
    end

    protected

    def fetch_people(ids)
      Person.search(Riddle::Query.escape(@term),
                    page: @page,
                    order: 'last_name asc, ' \
                           'first_name asc, ' \
                           "#{ThinkingSphinx::SphinxQL.weight[:select]} desc",
                    star: star_supported?,
                    with: { sphinx_internal_id: ids })
    end

    class << self

      def star_supported?
        version = Rails.application.class.sphinx_version
        version.nil? || version >= '2.1'
      end

    end

  end
end
