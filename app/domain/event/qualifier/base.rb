# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Event::Qualifier

  class Base < Struct.new(:participation)

    def qualifications
      obtained_qualifications_for(qualification_kind_ids)
    end

    private

    def has_all_qualifications?
      qualification_kind_ids.size == obtained_qualifications_for(qualification_kind_ids).size
    end

    def has_all_prolongations?(kind_ids)
      obtained_qualifications_for(kind_ids).size ==
      prolongable_qualifications(kind_ids).map(&:qualification_kind_id).uniq.size
    end

    def create_qualifications
      event.kind.qualification_kinds.each do |k|
        create_qualification(k)
      end
    end

    # creates new qualification for existing qualifications (prologation mechanism)
    def create_prolongations(kind_ids)
      if kind_ids.present?
        prolongable_qualifications(kind_ids).each do |q|
          create_qualification(q.qualification_kind)
        end
      end
    end

    # The qualifications a participant had before this event
    def prolongable_qualifications(kind_ids)
      person.qualifications
         .includes(:qualification_kind)
         .where(qualification_kind_id: kind_ids)
         .select { |quali| quali.reactivateable?(event.start_date) }
    end

    def create_qualification(kind)
      person.qualifications.create(qualification_kind: kind,
                                   origin: event.to_s,
                                   start_at: qualification_date)
    end

    def remove_qualifications(kind_ids)
      obtained_qualifications_for(kind_ids).each { |q| q.destroy }
    end

    def qualification_kind_ids
      @qualification_kind_ids ||= event.kind_id? ? event.kind.qualification_kind_ids.to_a : []
    end

    def prolongation_kind_ids
      @prolongation_kind_ids ||= event.kind.prolongation_ids.to_a
    end

    def obtained_qualifications_for(kind_ids)
      obtained_qualifications.select { |q| kind_ids.include?(q.qualification_kind_id) }
    end

    def obtained_qualifications
      @event_qualifications ||= person.qualifications.where(start_at: qualification_date).to_a
    end

    def qualification_date
      event.qualification_date
    end

    def person
      participation.person
    end

    def event
      participation.event
    end

  end
end
