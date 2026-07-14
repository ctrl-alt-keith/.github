# frozen_string_literal: true

require "minitest/autorun"

class PullRequestTemplateTest < Minitest::Test
  TEMPLATE_PATH = File.expand_path("../.github/pull_request_template.md", __dir__)

  def test_keeps_required_review_sections_once_and_in_order
    headings = File.readlines(TEMPLATE_PATH, chomp: true).grep(/^## /)

    assert_equal ["## Summary", "## Validation", "## Scope Notes"], headings
  end
end
