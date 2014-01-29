class AddQualifiedToParticipation < ActiveRecord::Migration

  def up
    data = Hash.new {|k,v| k[v] = []}

    participations = load_participations.find_each do |p|
      data[qualified?(p)] << p.id
    end

    add_column :event_participations, :qualified, :boolean

    say_with_time "updating participations (qualified: #{data[true].size}, not qualified: #{data[false].size})" do
      data.each { |qualified, ids| Event::Participation.where(id: ids).update_all(qualified: qualified) }
    end
  end

  def down
    remove_column :event_participations, :qualified
  end

  def qualified?(participation)
    OldQualifier.new(participation, Event::Qualifier.leader_types(participation.event)).qualified?
  end

  def load_participations
    Event::Participation.includes(:roles, event: [:dates, kind: [:qualification_kinds, :prolongations]], person: [qualifications: [:qualification_kind]])
      .where('events.type = "Event::Course"')
      .where('event_dates.finish_at < ?', Date.today)
  end

  # Required to allow including kinds in query
  class ::Event < ActiveRecord::Base
    belongs_to :kind
  end

  # extracted from old Base, Leader and Participation qualifiers
  class OldQualifier < Struct.new(:participation,:leader_types)
    def qualified?
      if leader?
        obtained_qualifications.present? && has_all_prolongations?(qualification_kind_ids)
      else
        obtained_qualifications.present? &&
          has_all_qualifications? &&
          has_all_prolongations?(prolongation_kind_ids)
      end
    end

    def leader?
      participation.roles.any? { |role| leader_types.include?(role.class) }
    end

    private

    def has_all_qualifications?
      qualification_kind_ids.size == obtained_qualifications_for(qualification_kind_ids).size
    end

    def has_all_prolongations?(kind_ids)
      obtained_qualifications_for(kind_ids).size ==
        prolongable_qualifications(kind_ids).map(&:qualification_kind_id).uniq.size
    end

    def prolongable_qualifications(kind_ids)
      person.qualifications
        .select { |quali| kind_ids.include?(quali.qualification_kind_id) }
        .select { |quali| quali.cover?(event.start_date) || quali.reactivateable?(event.start_date) }
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
      @event_qualifications ||= person.qualifications.select { |q| q.start_at == qualification_date }
    end

    def qualification_date
      @qualification_date ||= begin
                                last = event.dates.sort_by { |date| date.start_at }.last
                                last.finish_at || last.start_at
                              end.to_date
    end

    def person
      participation.person
    end

    def event
      participation.event
    end
  end

end
