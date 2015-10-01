require 'test_helper'

class ManufactureOrder::OrderTest < ActiveSupport::TestCase
  fixtures %w(
    manufacture_order/orders
    manufacture_order/rows
  )

  setup do
    @order = manufacture_order_orders(:mo_one)
  end

  test 'fixture should be valid' do
    assert @order.valid?
    assert_equal "Acme Corporation", @order.company.nimi
  end

  test 'model relations' do
    assert @order.rows.count > 0
    assert_equal "V", @order.rows.first.tyyppi
  end
end