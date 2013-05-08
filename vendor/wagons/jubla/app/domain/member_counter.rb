class MemberCounter

  attr_reader :year, :flock

  class << self
    def create_counts_for(flock)
      census = Census.current
      if census && !current_counts?(flock, census)
        new(census.year, flock).count!
        census.year
      else
        false
      end
    end

    def current_counts?(flock, census = Census.current)
      census && new(census.year, flock).exists?
    end
  end

  # create a new counter for with the given year and flock.
  # beware: the year is only used to store the results and does not
  # specify which roles to consider - only currently not deleted roles are counted.
  def initialize(year, flock)
    @year = year
    @flock = flock
  end

  def count!
    MemberCount.transaction do
      members_by_year.each do |born_in, people|
        count = new_member_count(born_in)
        count_members(count, people)
        count.save!
      end
    end
  end

  def exists?
    MemberCount.where(flock_id: flock.id, year: year).exists?
  end

  def state
    @state ||= flock.state
  end

  def members
    Person.joins(:roles).
           includes(:roles).
           where(roles: {group_id: flock.self_and_descendants, deleted_at: nil}).
           affiliate(false).
           uniq
  end

  private

  def members_by_year
    members.group_by {|p| p.birthday.try(:year) }
  end

  def new_member_count(born_in)
    count = MemberCount.new
    count.flock = flock
    count.state = state
    count.year = year
    count.born_in = born_in
    count
  end

  def count_members(count, people)
    people.each do |person|
      increment(count, count_field(person))
    end
  end

  def count_field(person)
    if person.roles.any? {|r| r.kind_of?(Group::ChildGroup::Child) }
      if person.male?
         :child_m
      else
         :child_f
      end
    else
      if person.male?
         :leader_m
      else
         :leader_f
      end
    end
  end

  def increment(count, field)
    val = count.send(field)
    count.send("#{field}=", val ? val+1 : 1)
  end

end
