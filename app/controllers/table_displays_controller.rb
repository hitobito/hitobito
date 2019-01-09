class TableDisplaysController < ApplicationController

  skip_authorization_check only: [:create]

  def create
    model = current_person.table_display_for(parent)
    model.update!(selected: model_params.fetch(:selected, []))
  end

  private

  def model_params
    @model_params ||= params.permit(:parent_id, :parent_type, selected: [])
  end

  def parent
    model_params[:parent_type].constantize.find(model_params[:parent_id])
  end

end
