#  Copyright (c) 2012-2018, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class TableDisplaysController < ApplicationController

  skip_authorization_check only: [:create]

  def create
    return unless TableDisplay.table_display_columns.keys.include? table_model_class

    model = current_person.table_display_for(table_model_class.constantize)
    model.update!(selected: model_params.fetch(:selected, []))
  end

  private

  def model_params
    @model_params ||= params.permit(:table_model_class, selected: [])
  end

  def table_model_class
    @table_model_class ||= model_params[:table_model_class]
  end

end
