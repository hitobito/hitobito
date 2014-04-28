# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::Qualifier

  class Base
    attr_reader :created, :prolonged, :participation

    delegate :qualified?, :person, :event, to: :participation
    delegate :qualification_date, to: :event

    def initialize(participation)
      @participation = participation

      @created = []
      @prolonged = []
    end

    def issue
      issue_qualifications
      participation.update_column(:qualified, true)
    end

    def revoke
      revoke_qualifications
      participation.update_column(:qualified, false)
    end

    private

    def create_qualifications
      @created = qualification_kinds.map { |kind| create(kind) }
    end

    # Creates new qualification for prolongable qualifications,
    # tracks what could and could not be prolonged
    def prolong_existing(kinds)
      @prolonged = prolongable_qualification_kinds(kinds)
      @prolonged.each { |kind| create(kind) }
    end

    def create(kind)
      person.qualifications
        .where(qualification_kind_id: kind.id, start_at: qualification_date)
        .first_or_create!(origin: event.to_s)
    end

    def prolongable_qualification_kinds(kinds)
      person.qualifications
         .includes(:qualification_kind)
         .where(qualification_kind_id: kinds.map(&:id))
         .select { |quali| quali.reactivateable?(event.start_date) }
         .map(&:qualification_kind)
    end

    def remove(kinds)
      obtained(kinds).each { |q| q.destroy }
    end

    # Qualifications set for this qualification_date (via preceeding #issue call in controller)
    def obtained(kinds = [])
      @obtained ||= person.qualifications.where(start_at: qualification_date,
                                                qualification_kind_id: kinds.map(&:id)).to_a
    end

    def qualification_kinds
      event.kind.qualification_kinds
    end

    def prolongation_kinds
      event.kind.prolongations
    end
  end
end
