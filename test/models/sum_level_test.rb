require 'test_helper'

class SumLevelTest < ActiveSupport::TestCase
  def setup
    @internal = sum_levels(:internal)
    @external = sum_levels(:external)
    @vat = sum_levels(:vat)
    @profit = sum_levels(:profit)
  end

  test "fixtures should be valid" do
    assert @internal.valid?
    assert @external.valid?
    assert @vat.valid?
    assert @profit.valid?
  end

  test "should return sum levels" do
    assert_equal 4, SumLevel::Internal.sum_levels.count
    assert SumLevel::Internal.sum_levels.is_a?(Hash)
  end

  test "should return constantized child class" do
    assert_equal SumLevel::External, SumLevel::External.child_class('U')
    #child_class can be called from SumLevel or its child
    assert_equal SumLevel::Internal, SumLevel.child_class('S')
    assert_equal SumLevel::Vat, SumLevel::Vat.child_class('A')
    assert_equal SumLevel::Profit, SumLevel::Profit.child_class('B')
  end

  test "should return sum level name" do
    assert_equal '3 TILIKAUDEN TULOS', @external.sum_level_name
  end

  test "sum level should not contain O with dots" do
    msg = 'Should not contain Ö'
    @internal.taso = 'Ö'
    refute @internal.valid?, msg

    @internal.taso = 'ö'
    assert @internal.valid?, msg

    @internal.taso = 'AÖ'
    refute @internal.valid?, msg

    @internal.taso = 'Aö'
    assert @internal.valid?, msg

    @external.taso = 'AÖ'
    refute @external.valid?, msg
  end

  test "internal and external sum level needs to begin with 1,2 or 3" do
    msg = 'Should begin with 1, 2 or 3'
    @internal.taso = '4'
    refute @internal.valid?, msg

    @external.taso = '4'
    refute @external.valid?, msg

    @internal.taso = '14'
    assert @internal.valid?, msg

    @external.taso = '114'
    assert @external.valid?, msg
  end

  test "profit sum level needs to be number" do
    msg = 'Profit sum level needs to be number'
    @profit.taso = 'A'
    refute @profit.valid?, msg

    @profit.taso = 'A1'
    refute @profit.valid?, msg

    @profit.taso = 1.0
    refute @profit.valid?, msg

    @profit.taso = ''
    refute @profit.valid?, msg

    @profit.taso = nil
    refute @profit.valid?, msg

    @profit.taso = 1
    assert @profit.valid?, msg
  end

  test "should have unique sum level" do
    msg = 'Sum level needs to be unique'
    existing_sum_level = @internal.taso

    new_sum_level = SumLevel::Internal.new
    new.sum_level.taso = existing_sum_level

    refute new_sum_level.valid?, msg

    new_sum_level.taso = '1111111'
    assert new_sum_level.valid?, msg
  end

  test "sum level should be required" do
    msg = 'sum_level: @internal.taso is required'
    @internal.taso = ''
    refute @internal.valid?, msg

    @internal.taso = nil
    refute @internal.valid?, msg

    @internal.taso = '1'
    assert @internal.valid?, msg
  end

end
