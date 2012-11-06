class MemberCounter
  
  attr_reader :year, :flock
  
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
  
  def state
    @state ||= flock.ancestors.where(type: Group::State.sti_name).first
  end
  
  def members
    Person.includes(:roles).
           where(roles: {group_id: flock.self_and_descendants}).
           where('roles.type NOT IN (?)', excluded_role_types).
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
  
  def excluded_role_types
    Group::Flock.role_types.select {|t| t.restricted || t.affiliate }.collect(&:sti_name)
  end
end