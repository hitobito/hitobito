class Group::Mover < Struct.new(:group)

  def candidates
    @candidate||= possible_candidates - [parent, group]
  end

  def perform(target)
    group.update_column(:parent_id, target.id)
  end

  private
  
  def parent
    group.parent
  end

  def possible_candidates
    return [] if parent.nil?
    parent.children | parent.hierarchy.map(&:siblings).flatten
  end

  def possible_candidates
    possible_groups.select { |candidate| matching_childgroup?(candidate) }
  end

  def matching_childgroup?(candidate)
    candidate.possible_children.include?(group.class)
  end

end
