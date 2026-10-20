# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
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

  def test_load_config_reports_invalid_yaml_as_a_configuration_error
    Tempfile.create(["dependabot", ".yml"], Dir.pwd) do |file|
      file.write("updates: [\n")
      file.flush

      error = assert_raises(DependabotConfigError) { load_config(file.path) }
      assert_includes(error.message, "invalid YAML:")
    end
  end

  def test_load_config_reports_missing_file_as_a_configuration_error
    missing_path = File.join(Dir.pwd, "missing-dependabot-config.yml")
    refute(File.exist?(missing_path))

    error = assert_raises(DependabotConfigError) { load_config(missing_path) }
    assert_includes(error.message, "does not exist")
  end

  def test_rejects_wrong_version
    config = valid_config
    config["version"] = 1

    assert_invalid("version must be 2") { config }
  end

  def test_rejects_missing_schedule_on_a_later_update
    config = valid_config
    config["updates"] << {
      "package-ecosystem" => "bundler",
      "directory" => "/"
    }

    assert_invalid("updates[1].schedule must be a mapping") { config }
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
