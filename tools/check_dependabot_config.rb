#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

CONFIG_PATH = File.expand_path("../.github/dependabot.yml", __dir__)

class DependabotConfigError < StandardError; end

def fail_check(message)
  warn "dependabot config: #{message}"
  exit 1
end

def load_config(path)
  YAML.load_file(path)
rescue Errno::ENOENT
  raise DependabotConfigError, "#{path} does not exist"
rescue Psych::SyntaxError => error
  raise DependabotConfigError, "invalid YAML: #{error.message}"
end

def validate_config!(config)
  raise DependabotConfigError, "root must be a mapping" unless config.is_a?(Hash)
  raise DependabotConfigError, "version must be 2" unless config["version"] == 2

  updates = config["updates"]
  unless updates.is_a?(Array) && !updates.empty?
    raise DependabotConfigError, "updates must be a non-empty list"
  end

  updates.each_with_index do |update, index|
    path = "updates[#{index}]"

    raise DependabotConfigError, "#{path} must be a mapping" unless update.is_a?(Hash)
    unless update["package-ecosystem"].is_a?(String) && !update["package-ecosystem"].empty?
      raise DependabotConfigError, "#{path}.package-ecosystem is required"
    end

    unless update["directory"].is_a?(String) && !update["directory"].empty?
      raise DependabotConfigError, "#{path}.directory is required"
    end

    schedule = update["schedule"]
    unless schedule.is_a?(Hash)
      raise DependabotConfigError, "#{path}.schedule must be a mapping"
    end
    unless schedule["interval"].is_a?(String) && !schedule["interval"].empty?
      raise DependabotConfigError, "#{path}.schedule.interval is required"
    end
  end

  github_actions_updates = updates.select do |update|
    update["package-ecosystem"] == "github-actions" && update["directory"] == "/"
  end

  unless github_actions_updates.length == 1
    raise DependabotConfigError, "must include exactly one github-actions update for directory /"
  end

  interval = github_actions_updates.fetch(0).fetch("schedule").fetch("interval")
  unless interval == "weekly"
    raise DependabotConfigError, "github-actions update for directory / must run weekly"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    validate_config!(load_config(CONFIG_PATH))
  rescue DependabotConfigError => error
    fail_check(error.message)
  end
end
