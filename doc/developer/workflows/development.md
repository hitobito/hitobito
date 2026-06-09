## Development

The development workflow is the default. It is meant for new and changed functionality.

- Start with a reason for the change, a goal that defines how the application should be improved for the user
- Always write a spec first
- The spec should define the desired state
- The spec should be failing at first
- Then add the implementation
- The spec should now be successful
- The whole spec-suite should also still be without errors
- You can run `rspec` to ensure that
- If that is not wanted, ask which parts of the suite should be run and run those
- If any spec fails, fix the new implementation until all specs pass
- Then, run `brakeman` to ensure no new security-problem have been added
- Lastly, run `rubocop` to ensure the code-style is good
- Create a commit-message, summarizing the need for the change
