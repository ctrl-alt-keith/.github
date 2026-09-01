# frozen_string_literal: true

require "minitest/autorun"
require_relative "../tools/check_workflow_config"

class WorkflowConfigTest < Minitest::Test
  CHECKOUT = "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1"
  SETUP_NODE = "actions/setup-node@820762786026740c76f36085b0efc47a31fe5020"

  def valid_workflow
    {
      "on" => {
        "pull_request" => nil,
        "push" => { "branches" => ["main"] }
      },
      "concurrency" => {
        "group" => "${{ github.workflow }}-${{ github.ref }}",
        "cancel-in-progress" => true
      },
      "permissions" => { "contents" => "read" },
      "jobs" => {
        "markdownlint" => {
          "timeout-minutes" => 10,
          "steps" => [
            {
              "uses" => CHECKOUT,
              "with" => { "fetch-depth" => 2, "persist-credentials" => false }
            },
            { "uses" => SETUP_NODE },
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
      { "uses" => CHECKOUT }
    ]

    assert_invalid("must check out the repository before make check") { workflow }
  end

  def test_rejects_markdownlint_install_after_make_check
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] = [
      {
        "uses" => CHECKOUT,
        "with" => { "fetch-depth" => 2, "persist-credentials" => false }
      },
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
          { "uses" => CHECKOUT },
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
          {
            "uses" => CHECKOUT,
            "with" => { "fetch-depth" => 2, "persist-credentials" => false }
          },
          { "run" => "make check" }
        ]
      }
    }

    assert_invalid("must install markdownlint-cli2 before make check") { workflow }
  end

  def test_rejects_missing_canonical_make_check
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] = [
      { "uses" => CHECKOUT },
      { "run" => "npm install --global markdownlint-cli2" },
      { "run" => "make check-github-config" }
    ]

    assert_invalid("must have exactly one canonical make check step") { workflow }
  end

  def test_rejects_multiple_canonical_make_check_steps
    workflow = valid_workflow
    workflow["jobs"]["extra"] = {
      "steps" => [
        { "uses" => CHECKOUT, "with" => { "fetch-depth" => 2 } },
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

  def test_rejects_missing_concurrency
    workflow = valid_workflow
    workflow.delete("concurrency")

    assert_invalid("concurrency must be a mapping") { workflow }
  end

  def test_rejects_concurrency_for_another_workflow_or_ref
    workflow = valid_workflow
    workflow["concurrency"]["group"] = "markdownlint"

    assert_invalid("concurrency must cancel superseded runs for the same workflow and ref") { workflow }
  end

  def test_rejects_concurrency_that_keeps_superseded_runs
    workflow = valid_workflow
    workflow["concurrency"]["cancel-in-progress"] = false

    assert_invalid("concurrency must cancel superseded runs for the same workflow and ref") { workflow }
  end

  def test_rejects_non_read_contents_permission
    workflow = valid_workflow
    workflow["permissions"] = { "contents" => "write" }

    assert_invalid("permissions must grant only contents: read") { workflow }
  end

  def test_rejects_additional_top_level_permission
    workflow = valid_workflow
    workflow["permissions"]["id-token"] = "write"

    assert_invalid("permissions must grant only contents: read") { workflow }
  end

  def test_rejects_job_level_permission_override
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["permissions"] = { "contents" => "write" }

    assert_invalid("jobs.markdownlint must not override permissions") { workflow }
  end

  def test_rejects_non_mapping_root
    assert_invalid("root must be a mapping") { [] }
  end

  def test_rejects_non_mapping_triggers
    workflow = valid_workflow
    workflow["on"] = ["pull_request", "push"]

    assert_invalid("on must be a mapping") { workflow }
  end

  def test_rejects_empty_jobs
    workflow = valid_workflow
    workflow["jobs"] = {}

    assert_invalid("jobs must be a non-empty mapping") { workflow }
  end

  def test_rejects_non_mapping_step
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"] << "make check"

    assert_invalid("jobs.markdownlint.steps[4] must be a mapping") { workflow }
  end

  def test_rejects_job_without_timeout
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"].delete("timeout-minutes")

    assert_invalid("timeout-minutes must be an integer from 1 to 15") { workflow }
  end

  def test_rejects_excessive_job_timeout
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["timeout-minutes"] = 30

    assert_invalid("timeout-minutes must be an integer from 1 to 15") { workflow }
  end

  def test_rejects_checkout_without_commit_history
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][0] = { "uses" => CHECKOUT }

    assert_invalid("needs one checkout with fetch-depth at least two") { workflow }
  end

  def test_rejects_checkout_with_insufficient_commit_history
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][0]["with"]["fetch-depth"] = 1

    assert_invalid("needs one checkout with fetch-depth at least two") { workflow }
  end

  def test_rejects_checkout_that_persists_credentials
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][0]["with"].delete("persist-credentials")

    assert_invalid("needs one checkout with fetch-depth at least two") { workflow }
  end

  def test_rejects_checkout_with_persisted_credentials_enabled
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][0]["with"]["persist-credentials"] = true

    assert_invalid("needs one checkout with fetch-depth at least two") { workflow }
  end

  def test_rejects_split_checkout_safety_requirements
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"].unshift(
      {
        "uses" => CHECKOUT,
        "with" => { "fetch-depth" => 2 }
      }
    )
    workflow["jobs"]["markdownlint"]["steps"][1]["with"]["fetch-depth"] = 1

    assert_invalid("needs one checkout with fetch-depth at least two") { workflow }
  end

  def test_rejects_additional_checkout_that_persists_credentials
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"].unshift(
      {
        "uses" => CHECKOUT,
        "with" => { "fetch-depth" => 2 }
      }
    )

    assert_invalid("every checkout before make check must disable persisted credentials") { workflow }
  end

  def test_rejects_unpinned_checkout_action
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][0]["uses"] = "actions/checkout@v7"

    assert_invalid("must pin actions/checkout to a 40-character commit SHA") { workflow }
  end

  def test_rejects_unpinned_setup_node_action
    workflow = valid_workflow
    workflow["jobs"]["markdownlint"]["steps"][1]["uses"] = "actions/setup-node@v7"

    assert_invalid("must pin actions/setup-node to a 40-character commit SHA") { workflow }
  end
end
