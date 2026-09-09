# Rake Tasks

In the table below you find all rake tasks which we make use of in hitobito. Run the following rake tasks inside rails, rails-test container:

| Task                      | Beschreibung                                                                              |
| ------------------------- |-------------------------------------------------------------------------------------------|
| `rake hitobito:abilities` | Output all abilities.                                                                     |
| `rake hitobito:roles`     | Output all groups, roles and permissions.                                                 |
| `rake annotate`           | Add column information as a comment to ActiveRecord models.                               |
| `rake rubocop`            | Executes `rubocop` on the whole project, except the `Wagons/PatchedMethod` cop, and fails if any offence is found. |
| `rake rubocop:changed`    | Executes `rubocop` on modified and untracked `.rb` files only, excluding `spec/` and `test/`. |
| `rake brakeman`           | Executes `brakeman`.                                                                      |
| `rake ci:check_pending`   | Fails if any spec is pending, or if the suite collects no examples at all.                 |
| `rake license:insert`     | Inserts the licence in all files.                                                         |
| `rake license:remove`     | Removes the licence from all files.                                                       |
| `rake license:update`     | Updates the licence in all files or inserts a new one.                                    |
---
