require 'minitest/autorun'
require_relative 'verifier_helper'
# Test Class for verifier_helper.rb file
class VerifierTest < Minitest::Test
  def setup
    @verify = D4.new
  end

  # Check Good Format
  def test_check_good_format
    input = '281974>669488'
    line_num = 1
    assert_output(nil) { @verify.check_format(input, line_num) }
  end

  # Check bad Format
  def test_check_bad_format
    assert_raises SystemExit do
      assert_output "Line 1: Could not parse transactions list 281974669488\nBLOCKCHAIN INVALID" do
        input = '281974669488'
        line_num = 1
        @verify.check_format(input, line_num)
      end
    end
  end

  # Check First Bad Address
  def test_check_first_bad_address
    assert_raises SystemExit do
      assert_output 'Line 1: Invalid address 1234567\nBLOCKCHAIN INVALID' do
        add = %w[1234567 123456]
        line_num = 1
        @verify.check_addresses(add, line_num)
      end
    end
  end

  # Check Second Bad Address
  def test_check_second_bad_address
    assert_raises SystemExit do
      assert_output 'Line 1: Invalid address 1234567\nBLOCKCHAIN INVALID' do
        add = %w[123456 1234567]
        line_num = 1
        @verify.check_addresses(add, line_num)
      end
    end
  end

  # Check Valid Block Number Method
  def test_check_num
    assert_raises SystemExit do
      assert_output 'Line 2: Invalid block number 1, should be 2\nBLOCKCHAIN INVALID' do
        block_no = '1'
        line_no = '2'
        @verify.check_num(block_no, line_no)
      end
    end
  end

  # Check Withdrawal Method for empty account
  def test_withdraw_empty_account
    coins = 10
    sender = 112_233
    address = ['445566']
    assert_equal -10, @verify.withdraw(coins, sender, address)
  end

  # Check Withdrawal Method for non empty method
  def test_withdraw_non_empty_account
    coins = 10
    sender = 112_233
    address = { '445566' => 100 }
    assert_equal -10, @verify.withdraw(coins, sender, address)
  end

  # Check Add Method for empty account
  def test_add_coins_empty_account
    coins = 10
    receiver = 112_233
    address = %w[445566]
    assert_equal 10, @verify.add(coins, receiver, address)
  end

  # Check Add Method for non empty account
  def test_add_coins_non_empty_account
    coins = 10
    receiver = 112_233
    address = { '445566' => 100 }
    assert_equal 10, @verify.add(coins, receiver, address)
  end

  # Check Bad Previous Hash
  def test_check_bad_prev_hash
    assert_raises SystemExit do
      assert_output 'Line 1: Previous hash was 1, should be 0\nBLOCKCHAIN INVALID' do
        p_hash = '0'
        line_num = '1'
        block_p_hash = ['1']
        hash = '1'
        @verify.check_prev_hash(p_hash, block_p_hash, hash, line_num)
      end
    end
  end

  # Check Good Previous Hash
  def test_check_good_prev_hash
    assert_raises SystemExit do
      assert_output '' do
        p_hash = '1'
        line_num = '1'
        block_p_hash = ['1']
        hash = '1'
        @verify.check_prev_hash(p_hash, block_p_hash, hash, line_num)
      end
    end
  end

  # Test for good values check_time method
  def test_check_good_time
    assert_output '' do
      time = '1553188611.560418000'
      prev_time = '0.0'
      line_num = 0
      @verify.check_time(time, prev_time, line_num)
    end
  end

  # Test for bad values check_time method
  def test_check_bad_time
    assert_raises SystemExit do
      assert_output 'Line 0: Previous timestamp 1553188611.560418000 >= new timestamp 0.0\nBLOCKCHAIN INVALID' do
        time = '0.0'
        prev_time = '1553188611.560418000'
        line_num = 0
        @verify.check_time(time, prev_time, line_num)
      end
    end
  end

  # Test for check_hash
  def test_check_hash
    assert_raises SystemExit do
      assert_output "Line 1: String '0|0|SYSTEM>281974(100)|1553188611.560418000' hash set to 6283, should be 1231\nBLOCKCHAIN INVALID" do
        found_hash = 1231
        line = ['0', '0', 'SYSTEM>281974(100)', '1553188611.560418000', "6283\n"]
        line_num = 1
        @verify.check_hash(found_hash, line, line_num)
      end
    end
  end

  # Test calc_hash function
  def test_calc_hash
    calc = {}
    line = '0|0|SYSTEM>281974(100)|1553188611.560418000|6283'
    assert_raises LocalJumpError, @verify.calc_hash(line, calc)
  end

  # Test for process_transactions
  def test_process_trans
    trans = '281974>669488(12):281974>669488(17):281974>217151(12):281974>814708(5):SYSTEM>933987(100)'
    line_num = 0
    address =  { '281974' => 100 }
    assert_equal %w[281974 669488 281974 669488 281974 217151 281974 814708 SYSTEM 933987], @verify.process_transactions(trans, line_num, address)
  end
end
