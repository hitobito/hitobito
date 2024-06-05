# Rake Tasks

In the table below you find all rake tasks which we make use of in hitobito. Run the following rake tasks inside rails, rails-test container:

| Task                      | Beschreibung                                                                              |
| ------------------------- |-------------------------------------------------------------------------------------------|
| `rake hitobito:abilities` | Output all abilities.                                                                     |
| `rake hitobito:roles`     | Output all groups, roles and permissions.                                                 |
| `rake annotate`           | Add column information as a comment to ActiveRecord models.                               |
| `rake rubocop`            | Executes the Rubocop Must Checks (`rubocop-must.yml`) and fails if any are found.         |
| `rake rubocop:report`     | Executes the Rubocop standard checks (`.rubocop.yml`) and generates a report for Jenkins. |
| `rake brakeman`           | Executes `brakeman`.                                                                      |
| `rake mysql`              | Loads the MySql test database configuration for the following tasks.                      |
| `rake license:insert`     | Inserts the licence in all files.                                                         |
| `rake license:remove`     | Removes the licence from all files.                                                       |
| `rake license:update`     | Updates the licence in all files or inserts a new one.                                    |
| `rake ci`                 | Executes the tasks for a commit build.                                                    |
| `rake ci:nightly`         | Executes the tasks for a nightly build.                                                   |
| `rake ci:wagon`           | Executes the tasks for the wagon commit builds.                                           |
| `rake ci:wagon:nightly`   | Executes the tasks for the Wagon Nightly Builds.                                          |
---
