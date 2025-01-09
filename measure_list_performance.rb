#!/usr/bin/env ruby

require "optparse"

options = {}
OptionParser.new do |opt|
  opt.on("--offset OFFSET") { |o| options[:offset] = o }
  opt.on("--limit LIMIT") { |o| options[:limit] = o }
end.parse!

def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

require_relative "config/environment"

branch = `git symbolic-ref HEAD | sed -e 's,.*/,,'`.strip
offset = options.fetch(:offset, 0).to_i
limit = options.fetch(:limit, 10).to_i
database = ActiveRecord::Base.connection.instance_variable_get(:@config)[:database]

batch_size = limit / 10
filename = "list-performance-#{database}-#{branch}-#{offset}-#{limit}.csv"

puts "Writing to #{filename}"
File.open(filename, "w") do |file|
  file.write CSV.generate_line(%w[id people seconds])
  MailingList.offset(offset).limit(limit).find_each.with_index do |list, index|
    puts "#{index} of #{limit}" if (index % batch_size) == 0
    file.flush if (index % batch_size) == 0
    start = now
    size = list.people.size
    file.write CSV.generate_line([list.id, size, (now - start).round(1)])
  end
end
