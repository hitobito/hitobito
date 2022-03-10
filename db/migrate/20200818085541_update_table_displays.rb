class UpdateTableDisplays < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      dir.up do
        TableDisplay.find_each do |t|
          t.send(:allow_only_known_attributes)
          t.save
        end
      end
    end
  end
end
