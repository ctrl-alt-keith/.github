# frozen_string_literal: true

require "minitest/autorun"

class OrgProfileTest < Minitest::Test
  PROFILE_PATH = File.expand_path("../profile/README.md", __dir__)

  def profile
    File.read(PROFILE_PATH)
  end

  def test_keeps_org_identity_as_the_only_top_level_heading
    headings = profile.lines.grep(/^# /).map(&:strip)

    assert_equal ["# ctrl-alt-keith"], headings
  end

  def test_keeps_ai_generation_disclosure
    assert_includes profile, "AI-generated. Human-verified."
  end
end
