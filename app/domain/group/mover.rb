class Group::Mover < Struct.new(:group)

  def candidates
    @candidate||= filter(possible_candidates) - [parent, group]
  end

  def perform(target)
    group.update_column(:parent_id, target.id)
  end

  private
  def parent
    group.parent
  end

  def possible_candidates
    parent.children | parent.hierarchy.map(&:siblings).flatten
  end

  def filter(candidates)
    candidates.select { |candidate| matching_childgroup?(candidate) }
  end

  def matching_childgroup?(candidate)
    candidate.possible_children.include?(group.class)
  end

end
