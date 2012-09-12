class GroupsController < CrudController
  
  skip_authorize_resource only: :index
  skip_authorization_check only: :index
  
  self.ability_types = {with_group: :all}
  
  def index
    flash.keep
    redirect_to Group.root
  end
  
  
end
