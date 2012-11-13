class CensusEvaluation::StateController < CensusEvaluation::BaseController
  
  self.sub_group_type = Group::Flock

  def remind
    authorize!(:remind_census, group)
    
    flock = sub_groups.find(params[:flock_id])
    CensusReminderJob.new(current_user, current_census, flock).enqueue!
    flash.now[:notice] = "Erinnerungsemail an #{flock.to_s} geschickt"
  end

end