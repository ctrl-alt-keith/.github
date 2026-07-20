# frozen_string_literal: true

require "minitest/autorun"
require_relative "../tools/check_workflow_config"

class WorkflowConfigTest < Minitest::Test
  def valid_workflow
    {
      "on" => {
        "pull_request" => nil,
        "push" => { "branches" => ["main"] }
      },
      "permissions" => { "contents" => "read" },
      "jobs" => {
        "markdownlint" => {
          "steps" => [
            { "uses" => "actions/checkout@v7" },
            { "run" => "npm install --global markdownlint-cli2" },
            { "run" => "make check" }
          ]
        }
      }
    }
  end

  def assert_invalid(message)
    error = assert_raises(WorkflowConfigError) { validate_workflow!(yield) }
    assert_includes(error.message, message)
  end

  def test_accepts_checkout_and_markdownlint_before_make_check_in_same_job
    validate_workflow!(valid_workflow)
  end

  def test_rejects_checkout_after_make_check
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] = [
      { "run" => "npm install --global markdownlint-cli2" },
      { "run" => "make check" },
      { "uses" => "actions/checkout@v7" }
    ]

    assert_invalid("must check out the repository before make check") { workflow }
  end

  def test_rejects_markdownlint_install_after_make_check
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] = [
      { "uses" => "actions/checkout@v7" },
      { "run" => "make check" },
      { "run" => "npm install --global markdownlint-cli2" }
    ]

    assert_invalid("must install markdownlint-cli2 before make check") { workflow }
  end

  def test_rejects_checkout_only_in_another_job
    workflow = valid_workflow
    workflow["jobs"] = {
      "setup" => {
        "steps" => [
          { "uses" => "actions/checkout@v7" },
          { "run" => "npm install --global markdownlint-cli2" }
        ]
      },
      "validate" => {
        "steps" => [
          { "run" => "make check" }
        ]
      }
    }

    assert_invalid("must check out the repository before make check") { workflow }
  end

  def test_rejects_markdownlint_install_only_in_another_job
    workflow = valid_workflow
    workflow["jobs"] = {
      "setup" => {
        "steps" => [
          { "run" => "npm install --global markdownlint-cli2" }
        ]
      },
      "validate" => {
        "steps" => [
          { "uses" => "actions/checkout@v7" },
          { "run" => "make check" }
        ]
      }
    }

    assert_invalid("must install markdownlint-cli2 before make check") { workflow }
  end

  def test_rejects_missing_canonical_make_check
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] = [
      { "uses" => "actions/checkout@v7" },
      { "run" => "npm install --global markdownlint-cli2" },
      { "run" => "make check-github-config" }
    ]

    assert_invalid("must have exactly one canonical make check step") { workflow }
  end

  def test_rejects_multiple_canonical_make_check_steps
    workflow = valid_workflow
    workflow["jobs"]["extra"] = {
      "steps" => [
        { "uses" => "actions/checkout@v7" },
        { "run" => "npm install --global markdownlint-cli2" },
        { "run" => "make check" }
      ]
    }

    assert_invalid("must have exactly one canonical make check step") { workflow }
  end

  def test_rejects_pull_request_target_trigger
    workflow = valid_workflow
    workflow["on"]["pull_request_target"] = nil

    assert_invalid("must not use pull_request_target") { workflow }
  end

  def test_rejects_non_read_contents_permission
    workflow = valid_workflow
    workflow["permissions"] = { "contents" => "write" }

    assert_invalid("permissions.contents must be read") { workflow }
  end
end
