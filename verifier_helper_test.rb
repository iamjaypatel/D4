require 'minitest/autorun'
require_relative 'verifier_helper'

# Test Class for verifier_helper.rb file
class VerifierTest < Minitest::Test
  
  def setup
    @verify = D4.new
  end
  # Check Bad Format
  def test_check_format
    input = "281974>669488"
    line = "1"
    assert_output(nil) { @verify.check_format(input, line) }
  end
  # Check Bad Address
  def test_check_bad_address
    add = "1234567"
    line_num = "1"
    out_put = "Line 1: Invalid address 1234567\nBLOCKCHAIN INVALID"
    assert_raise_message(out_put) { @verify.check_addresses(add, line_num) }
  end

  # Check Valid Block Number
  def test_check_num
    block_no = "1"
    line_no = "1"
    assert_output(nil) { @verify.check_num(block_no, line_no) }
  end

end
