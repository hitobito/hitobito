if !Rails.env.test? && ENV['PROMETHEUS_EXPORTER_HOST']
  require 'prometheus_exporter/middleware'
  require 'prometheus_exporter/instrumentation'

  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV['PROMETHEUS_EXPORTER_HOST'],
    port: ENV['PROMETHEUS_EXPORTER_PORT'] || PrometheusExporter::DEFAULT_PORT
  )

  # This reports stats per request like HTTP status and timings
  Rails.application.middleware.unshift PrometheusExporter::Middleware

  # This reports basic process stats like RSS and GC info
  proc_type = $ARGV.to_s.match?(/jobs\:work/) ? 'delayed_job' : 'puma_master'
  PrometheusExporter::Instrumentation::Process.start(
    type: proc_type,
    labels: { hostname: `hostname`.strip }
  )

  # This reports delayed job info
  PrometheusExporter::Instrumentation::DelayedJob.register_plugin

end
