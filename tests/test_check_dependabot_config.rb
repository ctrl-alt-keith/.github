# frozen_string_literal: true

require "minitest/autorun"
require_relative "../tools/check_dependabot_config"

class DependabotConfigTest < Minitest::Test
  def valid_config
    {
      "version" => 2,
      "updates" => [
        {
          "package-ecosystem" => "github-actions",
          "directory" => "/",
          "schedule" => { "interval" => "weekly" }
        }
      ]
    }
  end

  def assert_invalid(message)
    error = assert_raises(DependabotConfigError) { validate_config!(yield) }
    assert_includes(error.message, message)
  end

  def test_accepts_weekly_github_actions_updates
    validate_config!(valid_config)
  end

  def test_rejects_non_mapping_root
    assert_invalid("root must be a mapping") { [] }
  end

  def test_rejects_wrong_version
    config = valid_config
    config["version"] = 1

    assert_invalid("version must be 2") { config }
  end

  def test_rejects_empty_updates
    config = valid_config
    config["updates"] = []

    assert_invalid("updates must be a non-empty list") { config }
  end

  def test_rejects_non_mapping_update
    config = valid_config
    config["updates"] = ["github-actions"]

    assert_invalid("updates[0] must be a mapping") { config }
  end

  def test_rejects_missing_package_ecosystem
    config = valid_config
    config["updates"][0].delete("package-ecosystem")

    assert_invalid("updates[0].package-ecosystem is required") { config }
  end

  def test_rejects_missing_directory
    config = valid_config
    config["updates"][0].delete("directory")

    assert_invalid("updates[0].directory is required") { config }
  end

  def test_rejects_missing_schedule
    config = valid_config
    config["updates"][0].delete("schedule")

    assert_invalid("updates[0].schedule must be a mapping") { config }
  end

  def test_rejects_non_mapping_schedule
    config = valid_config
    config["updates"][0]["schedule"] = "weekly"

    assert_invalid("updates[0].schedule must be a mapping") { config }
  end

  def test_rejects_missing_schedule_interval
    config = valid_config
    config["updates"][0]["schedule"].delete("interval")

    assert_invalid("updates[0].schedule.interval is required") { config }
  end

  def test_rejects_missing_github_actions_root_update
    config = valid_config
    config["updates"][0]["directory"] = "/docs"

    assert_invalid("must include exactly one github-actions update for directory /") { config }
  end

  def test_rejects_duplicate_github_actions_root_updates
    config = valid_config
    config["updates"] << config["updates"][0].dup

    assert_invalid("must include exactly one github-actions update for directory /") { config }
  end

  def test_rejects_non_weekly_github_actions_updates
    config = valid_config
    config["updates"][0]["schedule"]["interval"] = "monthly"

    assert_invalid("github-actions update for directory / must run weekly") { config }
  end
end
