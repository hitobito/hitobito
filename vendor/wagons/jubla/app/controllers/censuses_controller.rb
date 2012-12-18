class CensusesController < CrudController
  
  before_filter :group
  
  after_create :send_invitation_mail
  
  decorates :group
  
  def create
    super(location: census_federation_group_path(Group.root))
  end
  
  private
  
  def send_invitation_mail
    CensusInvitationJob.new(@census).enqueue!
  end
  
  def group
    @group ||= Group.root
  end
  
end