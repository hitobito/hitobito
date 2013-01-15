class CensusEvaluation::FederationController < CensusEvaluation::BaseController
  
  self.sub_group_type = Group::State

  def index
    super

    respond_to do |format|
      format.html do
        @show_confirmation_ratios = (year == current_year)
        @flocks = flock_confirmation_ratios if @show_confirmation_ratios
      end
      format.csv do
        authorize!(:create, Census)
        csv = Export::CensusFlock.new(year).to_csv
        send_data csv, type: :csv
      end
    end
  end
  
  private
  
  def flock_confirmation_ratios
    @sub_groups.inject({}) do |hash, state|
      hash[state.id] = {confirmed: number_of_confirmations(state), total: number_of_flocks(state)}
      hash
    end
  end
  
  def number_of_confirmations(state)
    MemberCount.where(state_id: state.id, year: year).count(:flock_id, distinct: true)
  end
  
  def number_of_flocks(state)
    state.descendants.where(type: Group::Flock.sti_name).count
  end

end
