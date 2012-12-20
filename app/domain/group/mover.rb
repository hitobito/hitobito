class Group::Mover < Struct.new(:group)

  def candidates
    @candidate||= possible_candidates - [parent, group]
  end

  def perform(target)
    group.parent_id = target.id
    group.save
  end

  private
  
  def parent
    group.parent
  end

  def possible_groups
    if parent
      parent.children | parent.hierarchy.map(&:siblings).flatten
    else
      []
    end
  end

  def possible_candidates
    possible_groups.select { |candidate| matching_childgroup?(candidate) }
  end

  def matching_childgroup?(candidate)
    candidate.possible_children.include?(group.class)
  end

end
