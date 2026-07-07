#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

CONFIG_PATH = File.expand_path("../.github/dependabot.yml", __dir__)

def fail_check(message)
  warn "dependabot config: #{message}"
  exit 1
end

config =
  begin
    YAML.load_file(CONFIG_PATH)
  rescue Errno::ENOENT
    fail_check("#{CONFIG_PATH} does not exist")
  rescue Psych::SyntaxError => error
    fail_check("invalid YAML: #{error.message}")
  end

fail_check("root must be a mapping") unless config.is_a?(Hash)
fail_check("version must be 2") unless config["version"] == 2

updates = config["updates"]
unless updates.is_a?(Array) && !updates.empty?
  fail_check("updates must be a non-empty list")
end

updates.each_with_index do |update, index|
  path = "updates[#{index}]"

  fail_check("#{path} must be a mapping") unless update.is_a?(Hash)
  unless update["package-ecosystem"].is_a?(String) && !update["package-ecosystem"].empty?
    fail_check("#{path}.package-ecosystem is required")
  end

  unless update["directory"].is_a?(String) && !update["directory"].empty?
    fail_check("#{path}.directory is required")
  end

  schedule = update["schedule"]
  fail_check("#{path}.schedule must be a mapping") unless schedule.is_a?(Hash)
  unless schedule["interval"].is_a?(String) && !schedule["interval"].empty?
    fail_check("#{path}.schedule.interval is required")
  end
end

github_actions_updates = updates.select do |update|
  update["package-ecosystem"] == "github-actions" && update["directory"] == "/"
end

unless github_actions_updates.length == 1
  fail_check("must include exactly one github-actions update for directory /")
end

interval = github_actions_updates.fetch(0).fetch("schedule").fetch("interval")
fail_check("github-actions update for directory / must run weekly") unless interval == "weekly"
