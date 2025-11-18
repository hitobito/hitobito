class RenamePeopleFilterRoleKindCreated < ActiveRecord::Migration[8.0]
  def change
    PeopleFilter.find_each do |people_filter|
      people_filter.filter_chain.filters.each do |filter|
        if filter.attr == "role" && filter.args["kind"] == "created"
          filter.args["kind"] = "started"
        end
      end

      people_filter.save
    end
  end
end
