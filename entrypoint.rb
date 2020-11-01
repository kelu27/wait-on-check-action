#!/usr/bin/env ruby
require "net/http"
require "uri"
require "json"

def query_check_status(ref, check_name, token, repo, owner)
  defined?(repo) && owner ? repository = owner + "/" + repo : repository = ENV["GITHUB_REPOSITORY"]
  uri = URI.parse("https://api.github.com/repos/#{repository}/commits/#{ref}/check-runs?check_name=#{check_name}")
  request = Net::HTTP::Get.new(uri)
  request["Accept"] = "application/vnd.github.antiope-preview+json"
  request["Authorization"] = "token #{token}"
  req_options = {
    use_ssl: uri.scheme == "https"
  }
  response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http|
    http.request(request)
  }
  parsed = JSON.parse(response.body)
  return [nil, nil] if parsed["total_count"].zero?

  [
    parsed["check_runs"][0]["conclusion"]
  ]
end

# check_name is the name of the "job" key in a workflow, or the full name if the "name" key
# is provided for job. Probably, the "name" key should be kept empty to keep things short
ref, check_name, token, wait, repo, owner = ARGV
wait = wait.to_i
conclusion = query_check_status(ref, check_name, token, repo, owner)

if conclusiom.nil?
  puts "The requested check was never run against this ref, exiting..."
  exit(false)
end

while conclusiom != "success"
  puts "The requested check hasn't completed yet, will check back in #{wait} seconds..."
  sleep(wait)
  conclusiom, conclusion = query_check_status(ref, check_name, token)
end

puts "Check completed with a conclusion #{conclusiom}"
# Bail if check is not success
exit(false) unless conclusion == "success"
