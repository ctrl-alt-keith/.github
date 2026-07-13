#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

WORKFLOW_PATH = File.expand_path("../.github/workflows/markdownlint.yml", __dir__)

class WorkflowConfigError < StandardError; end

def fail_check(message)
  warn "workflow config: #{message}"
  exit 1
end

def load_workflow(path)
  YAML.load_file(path)
rescue Errno::ENOENT
  raise WorkflowConfigError, "#{path} does not exist"
rescue Psych::SyntaxError => error
  raise WorkflowConfigError, "invalid YAML: #{error.message}"
end

def mapping!(value, message)
  raise WorkflowConfigError, message unless value.is_a?(Hash)

  value
end

def step_list!(job_name, job)
  mapping!(job, "jobs.#{job_name} must be a mapping")
  steps = job["steps"]
  unless steps.is_a?(Array) && !steps.empty?
    raise WorkflowConfigError, "jobs.#{job_name}.steps must be a non-empty list"
  end

  steps.each_with_index do |step, index|
    mapping!(step, "jobs.#{job_name}.steps[#{index}] must be a mapping")
  end
end

def make_check_step?(step)
  step["run"].is_a?(String) && step["run"].lines.any? { |line| line.strip == "make check" }
end

def checkout_step?(step)
  step["uses"].is_a?(String) && step["uses"].start_with?("actions/checkout@")
end

def markdownlint_install_step?(step)
  step["run"].is_a?(String) && step["run"].include?("markdownlint-cli2")
end

def validate_make_check_job_order!(jobs)
  make_check_locations = []

  jobs.each do |job_name, job|
    steps = step_list!(job_name, job)
    steps.each_with_index do |step, index|
      make_check_locations << [job_name, steps, index] if make_check_step?(step)
    end
  end

  unless make_check_locations.length == 1
    raise WorkflowConfigError, "must have exactly one canonical make check step"
  end

  job_name, steps, make_check_index = make_check_locations.first
  prior_steps = steps.first(make_check_index)

  unless prior_steps.any? { |step| checkout_step?(step) }
    raise WorkflowConfigError, "jobs.#{job_name} must check out the repository before make check"
  end

  return if prior_steps.any? { |step| markdownlint_install_step?(step) }

  raise WorkflowConfigError, "jobs.#{job_name} must install markdownlint-cli2 before make check"
end

def validate_workflow!(workflow)
  mapping!(workflow, "root must be a mapping")

  events = workflow.key?("on") ? workflow["on"] : workflow[true]
  mapping!(events, "on must be a mapping")

  raise WorkflowConfigError, "must run on pull_request" unless events.key?("pull_request")

  push = mapping!(events["push"], "push must be a mapping")
  branches = push["branches"]
  unless branches.is_a?(Array) && branches.include?("main")
    raise WorkflowConfigError, "push.branches must include main"
  end

  if events.key?("pull_request_target")
    raise WorkflowConfigError, "must not use pull_request_target"
  end

  permissions = mapping!(workflow["permissions"], "permissions must be a mapping")
  unless permissions["contents"] == "read"
    raise WorkflowConfigError, "permissions.contents must be read"
  end

  jobs = mapping!(workflow["jobs"], "jobs must be a non-empty mapping")
  raise WorkflowConfigError, "jobs must be a non-empty mapping" if jobs.empty?

  validate_make_check_job_order!(jobs)
end

if $PROGRAM_NAME == __FILE__
  begin
    validate_workflow!(load_workflow(WORKFLOW_PATH))
  rescue WorkflowConfigError => error
    fail_check(error.message)
  end
end
