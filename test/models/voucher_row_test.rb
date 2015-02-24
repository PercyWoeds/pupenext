require 'test_helper'

class Head::VoucherRowTest < ActiveSupport::TestCase
  setup do
    @row = head_voucher_rows(:one)
  end

  test 'fixture should be valid' do
    assert @row.valid?, @row.errors.full_messages
    assert_equal "Acme Corporation", @row.voucher.company.nimi
  end

  test 'model relations' do
    assert_equal '100', @row.account.tilino
    assert_not_nil @row.voucher
    assert_not_nil head_voucher_rows(:two).purchase_invoice
    assert_not_nil head_voucher_rows(:three).purchase_order
    assert_not_nil head_voucher_rows(:four).sales_invoice
    assert_not_nil head_voucher_rows(:five).sales_order
    assert_not_nil head_voucher_rows(:six).commodity
  end

  test 'must happen in current active fiscal period' do
    params = {
      tilikausi_alku: '2015-01-01',
      tilikausi_loppu: '2015-06-30'
    }
    @row.voucher.company.update_attributes! params

    new_row = @row.dup
    new_row.tapvm = '2017-31-1'
    refute new_row.valid?
  end

  test 'allows only one account per commodity id' do
    # Commodity already has account number that differs from this row
    commodity = fixed_assets_commodities(:commodity_one)
    assert_not_equal commodity.procurement_number, @row.tilino
    @row.commodity_id = commodity.id
    refute @row.valid?

    # Accepts the same account number
    @row.tilino = commodity.procurement_number
    assert @row.valid?
  end
end