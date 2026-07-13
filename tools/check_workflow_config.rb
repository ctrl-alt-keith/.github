#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

WORKFLOW_PATH = File.expand_path("../.github/workflows/markdownlint.yml", __dir__)

def fail_check(message)
  warn "workflow config: #{message}"
  exit 1
end

workflow =
  begin
    YAML.load_file(WORKFLOW_PATH)
  rescue Errno::ENOENT
    fail_check("#{WORKFLOW_PATH} does not exist")
  rescue Psych::SyntaxError => error
    fail_check("invalid YAML: #{error.message}")
  end

fail_check("root must be a mapping") unless workflow.is_a?(Hash)

events = workflow.key?("on") ? workflow["on"] : workflow[true]
fail_check("on must be a mapping") unless events.is_a?(Hash)

fail_check("must run on pull_request") unless events.key?("pull_request")

push = events["push"]
fail_check("push must be a mapping") unless push.is_a?(Hash)

branches = push["branches"]
unless branches.is_a?(Array) && branches.include?("main")
  fail_check("push.branches must include main")
end

if events.key?("pull_request_target")
  fail_check("must not use pull_request_target")
end

permissions = workflow["permissions"]
fail_check("permissions must be a mapping") unless permissions.is_a?(Hash)
fail_check("permissions.contents must be read") unless permissions["contents"] == "read"

jobs = workflow["jobs"]
fail_check("jobs must be a non-empty mapping") unless jobs.is_a?(Hash) && !jobs.empty?

all_steps = jobs.flat_map do |job_name, job|
  fail_check("jobs.#{job_name} must be a mapping") unless job.is_a?(Hash)

  steps = job["steps"]
  fail_check("jobs.#{job_name}.steps must be a non-empty list") unless steps.is_a?(Array) && !steps.empty?

  steps.each_with_index do |step, index|
    fail_check("jobs.#{job_name}.steps[#{index}] must be a mapping") unless step.is_a?(Hash)
  end
end

uses_checkout = all_steps.any? do |step|
  step["uses"].is_a?(String) && step["uses"].start_with?("actions/checkout@")
end

fail_check("must check out the repository before validation") unless uses_checkout

installs_markdownlint = all_steps.any? do |step|
  step["run"].is_a?(String) && step["run"].include?("markdownlint-cli2")
end

fail_check("must install markdownlint-cli2 for make check") unless installs_markdownlint

runs_make_check = all_steps.any? do |step|
  step["run"].is_a?(String) && step["run"].lines.any? { |line| line.strip == "make check" }
end

fail_check("must run canonical make check") unless runs_make_check
