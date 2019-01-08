class TableDisplaysController < ApplicationController

  skip_authorization_check only: [:create]

  def create
    model = find_or_initialize
    model.update!(model_params.slice(:selected))
  end

  def find_or_initialize
    current_person.table_displays
      .find_or_initialize_by(model_params.slice(:parent_id, :parent_type))
  end

  private

  def model_params
    @model_params ||= params.permit(:parent_id, :parent_type, selected: [])
  end
end
