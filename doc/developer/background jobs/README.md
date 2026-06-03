# Background Jobs
We handle long running and blocking tasks with background jobs. Examples for these tasks are Jobs that export data for a download, the MailChimp sync and the address sync.

### Delayed Job
We use [delayed_job](https://github.com/collectiveidea/delayed_job) as our queue system and backend for ActiveJob. All job classes inherit from the class `BaseJob`, which implements
all the basic functionality a job needs, like the `enqueue!` method. This means that for custom job classes we dont use `Active Job`.
Jobs must override the `perform` method, which will be called by the `Delayed Job worker` when it picks up the job.

### JobObservation and the job overview
#### Explanation
The job overview is a view that shows to a user all the jobs they enqueued. For each job the following data is shown:
Job status, progress if provided, start and end timestamp, number of attempts, and, for download jobs,
a download button to download the generated file.

#### Usage

To make jobs appear on the job overview when enqueued, the respective job class must prepend the `ObservableJob` concern.
All export jobs are observable jobs because the class `ExportBaseJob`, from which all export jobs inherit,
prepends the concern.

Each job observation is associated with the user that started the job and only that user can see this job observation on their
job overview. The user is either read from the `@user_id` instance variable or `Auth.current_person`. Additionally an attr_writer
is provided to set `@user_id`. This can be helpful if you want to enqueue jobs from within another job and need to pass down the
`@user_id` so these jobs also appear on the job overview. Attention: Explicitly setting `@user_id` to nil will prevent a check of
`Auth.current_person`, meaning there is a difference between the instance variable being undefined and it being nil.

If a job that prepends the `ObservableJob` concern is run from outside a user context, meaning there is no person the job
could be associated with, the job runs anyway without creating and updating an instance of `JobObservation`.

#### Possible pitfalls
- `BaseJob` provides a class attribute called `parameters` which is an array of symbols that contains the names of all
instance methods that should be serialized with the job class. For observable jobs this must contain `job_observation_id`.
It is already added to the array in the `ObservableJob` concern so a declaration like this is sufficient:
`self.parameters += [:some_other_param]`
- Export jobs can't be run from outside a user context because they export a file the user should be able to download.
Therefore there must be an instance of `JobObservation` associated with the Job.
