class Group::Mover < Struct.new(:group)

  def candidates
    @candidate ||= possible_candidates - [group, group.parent]
  end

  def perform(target)
    group.parent_id = target.id
    group.save
  end

  private

  def possible_candidates
    possible_groups.select { |candidate| matching_childgroup?(candidate) }
  end

  def possible_groups
    group.hierarchy.collect {|g| g.self_and_siblings.without_deleted.order_by_type }.flatten
  end

  def matching_childgroup?(candidate)
    candidate.possible_children.include?(group.class)
  end

end
