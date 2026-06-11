## Development

This workflow is meant for new and changed functionality.

- Start with a reason for the change, a goal that defines how the application should be improved for the user
- Always write a spec first
- The spec should define the desired state
- The spec should be failing at first
- Then add the implementation
- Do not touch locales other than "de"
- The spec should now be successful
- Run the specs for all touched classes to avoid regressions
- Then, run `brakeman` to ensure no new security-problem have been added
- Lastly, run `rubocop` to ensure the code-style is good
- Create a commit-message, summarizing the need for the change
