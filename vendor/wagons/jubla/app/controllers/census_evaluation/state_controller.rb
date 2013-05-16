class CensusEvaluation::StateController < CensusEvaluation::BaseController

  self.sub_group_type = Group::Flock

  def remind
    authorize!(:remind_census, group)

    flock = sub_groups.find(params[:flock_id])
    CensusReminderJob.new(current_user, current_census, flock).enqueue!
    notice = "Erinnerungsemail an #{flock.to_s} geschickt"

    respond_to do |format|
      format.html { redirect_to census_state_group_path(group), notice: notice }
      format.js { flash.now.notice = notice }
    end
  end

end