module RenderPeopleCsv

  def render_csv(people, group)
    csv = params[:details] && can?(:index_full_people, group) ?
      Export::CsvPeople.export_full(people) :
      Export::CsvPeople.export_address(people)
    send_data csv, type: :csv
  end

end
