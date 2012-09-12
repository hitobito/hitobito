class GroupsController < CrudController
  
  def index
    redirect_to Group.root
  end
  
end
