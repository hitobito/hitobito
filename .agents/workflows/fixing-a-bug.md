## Fixing a Bug

The bug fixing workflow aims to resolve an error of mostly unknown cause. It might be an edge-case or data-based exception that is not being handled.

- Start with a reason for the bugfix, an error that affects the user
- Verify that `rubocop` and `brakeman` report no errors locally
- Write a spec to reproduce the bug BEFORE changing any other code
- The spec should define the desired state
- The spec should be failing at first
- Then add the implementation
- The spec should now be successful
- Then, run `brakeman` to ensure no new security-problem have been added
- Lastly, run `rubocop` to ensure the code-style is good
- Write a commit-message, summarizing the need for the change
