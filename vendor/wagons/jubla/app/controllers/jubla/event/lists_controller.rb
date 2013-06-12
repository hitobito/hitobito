module Jubla::Event::ListsController
  extend ActiveSupport::Concern
  
  included do
    alias_method_chain :render_courses_csv, :additions
  end
  
  def render_courses_csv_with_additions
    csv = ::Export::Courses::JublaList.new(@courses_by_kind.values.flatten).to_csv
    send_data csv, type: :csv
  end
end
