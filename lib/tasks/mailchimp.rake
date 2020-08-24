require 'rubygems'
require 'rubygems/package'
require 'zlib'
require 'fileutils'

namespace :mailchimp do
  # Extract batch id from results, get status (generate response file), download and extract
  class Client
    def initialize(mailing_list)
      @list = mailing_list
    end

    def directory
      name = [@list.id, @list.name.parameterize, @list.people.to_a.count].join('-')
      Rails.root.join("tmp/mailchimp/#{name}").tap do |dir|
        FileUtils.mkdir_p(dir)
      end
    end

    def operations
      client = Synchronize::Mailchimp::Client.new(@list)
      @list.mailchimp_result.data.each do |operation, hash|
        fail "unexpected batch count " unless hash.one?

        outcome, *args = hash.flatten
        next if outcome == :success

        batch_id = args.flatten.last[%r{/(\w+)-response.tar.gz}, 1]
        yield client, operation, batch_id, outcome
      end
    end

    def fetch_operations
      operations.each do |client, operation, batch_id, outcome|
        response = Faraday.get(client.fetch_batch(batch_id)).body
        file = directory.join("#{operation}-#{outcome}/result.tgz")
        FileUtils.mkdir_p(file.dirname)
        File.binwrite(file, response)
        fail "error extracting #{file}" unless system("tar -C #{file.dirname} -zxf #{file} ")
      end
    end
  end

  # Batch runs expire after 10 days
  desc 'Fetch non expired mailchimp batch runs'
  task :fetch => [:environment] do
    MailingList.mailchimp.where('mailchimp_last_synced_at > ?', 10.day.ago) do
      Client.new(list).fetch
    end
  end

  desc 'List largest files'
  task :list do
    sh "find ./ -iname '*.json'  -printf '%s %p\n'| sort -nr | head -10"
  end

  desc 'Show details for file'
  task :details, :file do |t, args|
    # Show details for error code 400
    sh "cat #{args[:file]} | jq ' .[] | select(.status_code==400) | .response | fromjson | .detail'"
    # Count status codes
    sh "cat #{args[:file]} | jq ' .[].status_code' | sort | uniq -c"
  end
end
