require 'test_helper'

class Reports::DepreciationDifferenceReportTest < ActiveSupport::TestCase
  fixtures %w(
    accounts
    fiscal_years
    fixed_assets/commodities
    fixed_assets/commodity_rows
    head/voucher_rows
    heads
    qualifiers
    sum_levels
  )

  setup do
    @acme = companies :acme

    @report = Reports::DepreciationDifferenceReport.new(
      company_id: @acme.id,
      start_date: Date.today.beginning_of_year.to_s,
      end_date:   Date.today.end_of_year,
    )
  end

  test 'class' do
    assert_not_nil @report
  end

  test 'required relations' do
    assert @acme.sum_level_commodities.count > 0
  end

  test 'returns response hierarcy' do
    data = @report.data
    assert_equal Reports::DepreciationDifferenceReport::Response, data.class
    assert_equal "0.0", data.deprication_total.to_s
    assert_equal "111.0", data.difference_total.to_s
    assert_equal "1001.0", data.evl_total.to_s

    sum_levels = data.sum_levels
    assert_equal Array, sum_levels.class

    sum_level = sum_levels.first
    assert_equal Reports::DepreciationDifferenceReport::SumLevel, sum_level.class
    assert_equal "Koneet ja kalusto", sum_level.name
    assert_equal "0.0", sum_level.deprication_total.to_s
    assert_equal "111.0", sum_level.difference_total.to_s
    assert_equal "1001.0", sum_level.evl_total.to_s

    accounts = sum_level.accounts
    assert_equal Array, accounts.class

    account = accounts.first
    assert_equal Reports::DepreciationDifferenceReport::Account, account.class
    assert_equal "EVL poistoerovastatili", account.name
    assert_equal "0.0", account.deprication_total.to_s
    assert_equal "111.0", account.difference_total.to_s
    assert_equal "1001.0", account.evl_total.to_s

    commodities = account.commodities
    assert_equal Array, commodities.class

    commodity = commodities.first
    assert_equal Reports::DepreciationDifferenceReport::Commodity, commodity.class
    assert_equal "This is a commodity!", commodity.name
    assert_equal "0.0", commodity.deprication.to_s
    assert_equal "111.0", commodity.difference.to_s
    assert_equal "1001.0", commodity.evl.to_s
  end
end
