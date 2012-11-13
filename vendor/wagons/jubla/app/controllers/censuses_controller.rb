class CensusesController < CrudController
  
  def create
    super(location: census_federation_group_path(Group.root))
  end
  
end