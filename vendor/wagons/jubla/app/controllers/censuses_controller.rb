class CensusesController < CrudController
  
  after_create :send_invitation_mail
  
  def create
    super(location: census_federation_group_path(Group.root))
  end
  
  private
  
  def send_invitation_mail
    CensusInvitationJob.new(@census).enqueue!
  end
  
end