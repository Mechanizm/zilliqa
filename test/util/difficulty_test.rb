require 'test_helper'

class DifficultyTest < Minitest::Test
  def test_hashpower_conversion
    ds_difficulty = 163
    expected_hashpower = 346425454453366

    assert_equal expected_hashpower, Zilliqa::Util::Difficulty.to_hashpower_divided(ds_difficulty)

    shard_difficulty = 104
    expected_hashpower = 2198989701120

    assert_equal expected_hashpower, Zilliqa::Util::Difficulty.to_hashpower_divided(shard_difficulty)
  end
end
