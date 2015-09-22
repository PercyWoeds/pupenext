require 'test_helper'

class RevenueExpenditureReportTest < ActiveSupport::TestCase
  fixtures %w(heads head/voucher_rows accounts)

  setup do
    # Fetch required accounts
    invoice = heads(:si_one)

    @receivable_regular   = invoice.company.myyntisaamiset
    @receivable_factoring = invoice.company.factoringsaamiset
    @receivable_concern   = invoice.company.konsernimyyntisaamiset

    @payable_regular = invoice.company.ostovelat
    @payable_concern = invoice.company.konserniostovelat
  end

  teardown do
    # make sure other tests don't mess up our dates
    travel_back
  end

  test 'initialization with wrong values' do
    assert_raise ArgumentError do
      RevenueExpenditureReport.new(nil)
    end

    assert_raise ArgumentError do
      RevenueExpenditureReport.new('')
    end
  end

  test 'history revenue' do
    # Let's save one invoice and delete the rest
    invoice_one = heads(:si_one).dup
    Head::SalesInvoice.delete_all

    # First is unpaid
    invoice_one.alatila = 'X'
    invoice_one.erpcm = Date.today - 1.week
    invoice_one.mapvm = 0
    invoice_one.save!

    # Add accounts receivable vourcher rows (and others, which should not matter)
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: 153.39,  tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: '100',   summa: 100.01, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: '200',   summa: 200.35, tapvm: invoice_one.tapvm)

    # Second invoice is paid, on correct week, should not matter
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.mapvm = Date.today - 1.week
    invoice_two.save!

    # Add accounts receivable vourcher rows (which should not matter)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 300.05, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 100.15, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 200.20, tapvm: invoice_two.tapvm)

    # Fourth invoice is unpaid, correct week, but has company accounts receivable (should not matter)
    invoice_four = invoice_one.dup
    invoice_four.erpcm = Date.today - 1.week
    invoice_four.mapvm = 0
    invoice_four.save!

    # Add concern accounts receivable vourcher rows (which should not matter)
    invoice_four.accounting_rows.create!(tilino: @receivable_concern, summa: 350.05, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_concern, summa: 120.15, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_concern, summa: 230.20, tapvm: invoice_four.tapvm)

    # Fifth invoice is unpaid, correct week, but has factoring receivable (should not matter)
    invoice_five = invoice_one.dup
    invoice_five.erpcm = Date.today - 1.week
    invoice_five.mapvm = 0
    invoice_five.summa = 84.1
    invoice_five.save!

    # Add factoring receivable vourcher rows (which should not matter)
    invoice_five.accounting_rows.create!(tilino: @receivable_factoring, summa: 29.3, tapvm: invoice_five.tapvm)
    invoice_five.accounting_rows.create!(tilino: @receivable_factoring, summa: 11.5, tapvm: invoice_five.tapvm)
    invoice_five.accounting_rows.create!(tilino: @receivable_factoring, summa: 43.3, tapvm: invoice_five.tapvm)

    # history_revenue should include invoice one and four.
    response = RevenueExpenditureReport.new(1).data
    assert_equal 153.39, response[:history_revenue]
  end

  test 'history expenditure' do
    # Let's save three invoices and delete the rest
    invoice_one = heads(:pi_H).dup
    invoice_two = heads(:pi_Y).dup
    invoice_three = heads(:pi_M).dup
    Head::PurchaseInvoice.delete_all

    # First is unpaid
    invoice_one.erpcm = Date.today - 1.week
    invoice_one.mapvm = 0
    invoice_one.save!

    # Add accounts payable rows, these should show up, others should not
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -46.61, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_concern, summa: -46.61, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: -46.61, tapvm: invoice_one.tapvm)

    # Second invoice is paid
    invoice_two.mapvm = Date.today - 2.days
    invoice_two.erpcm = Date.today - 2.days
    invoice_two.save!

    # Add accounts payable rows, these should not show up, as invoice is paid
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -46.61, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_concern, summa: -46.61, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: -46.61, tapvm: invoice_two.tapvm)

    # Third is unpaid approved invoice
    invoice_three.erpcm = Date.today - 1.week
    invoice_three.mapvm = 0
    invoice_three.save!

    # Add accounts payable rows, these should show up, others should not
    invoice_three.accounting_rows.create!(tilino: @payable_regular, summa: -12.14, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @payable_regular, summa: -15.86, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @payable_concern, summa: -46.61, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @receivable_regular, summa: -46.61, tapvm: invoice_three.tapvm)

    # history_expenditure should include invoice one and three
    response = RevenueExpenditureReport.new(1).data
    assert_equal 128, response[:history_expenditure]
  end

  test 'overdue accounts payable' do
    # Let's save one invoice and delete the rest
    invoice_one = heads(:pi_H).dup
    Head::PurchaseInvoice.delete_all

    # We must travel to friday, since accounts payable calculated between monday - yesterday.
    # Otherwise these test would not work on mondays.
    this_friday = Date.today.beginning_of_week.advance(days: 4)
    travel_to this_friday

    # First is unpaid and within current week
    invoice_one.erpcm = Date.today - 1.day
    invoice_one.mapvm = 0
    invoice_one.save!

    # Add two correct payable regular rows, others should be dismissed
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_concern, summa: -543.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: -446.61, tapvm: invoice_one.tapvm)

    response = RevenueExpenditureReport.new(1).data
    assert_equal 106.78, response[:overdue_accounts_payable], "Weekstart #{Date.today.beginning_of_week} Today #{Date.today} Duedate #{invoice_one.erpcm} Yesterday #{Date.today - 1.day}"

    # Second invoice is unpaid, but its overdue date is last week
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.mapvm = 0
    invoice_two.save!

    # Add two correct payable regular rows and others, should be dismissed because they're last week
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_concern, summa: -53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: -46.61, tapvm: invoice_two.tapvm)

    response = RevenueExpenditureReport.new(1).data
    assert_equal 106.78, response[:overdue_accounts_payable]

    # Third invoice is paid
    invoice_three = invoice_one.dup
    invoice_three.erpcm = Date.today - 1.day
    invoice_three.mapvm = Date.today - 1.day
    invoice_three.save!

    # Add two correct payable regular rows and others, all should be dismissed. as it is paid.
    invoice_three.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @payable_regular, summa: -53.39, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @payable_concern, summa: -53.39, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @receivable_regular, summa: -46.61, tapvm: invoice_three.tapvm)

    response = RevenueExpenditureReport.new(1).data
    assert_equal 106.78, response[:overdue_accounts_payable]
  end

  test 'overdue accounts receivable' do
    # Let's save one invoice and delete the rest
    invoice_one = heads(:si_one).dup
    Head::SalesInvoice.delete_all

    # We must travel to friday, since accounts receivable calculated between monday - yesterday.
    # Otherwise these test would not work on mondays.
    this_friday = Date.today.beginning_of_week.advance(days: 4)
    travel_to this_friday

    # First is unpaid, sent, and due yesterday, should be included
    invoice_one.erpcm = Date.today - 1.day
    invoice_one.mapvm = 0
    invoice_one.alatila = 'X'
    invoice_one.save!

    # Only regular accounting rows should be included
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: 53.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_factoring, summa: 53.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_one.tapvm)

    # overdue_accounts_receivable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 53.39, response[:overdue_accounts_receivable].to_f

    # Second is unpaid, but is due last week, should not be included
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.mapvm = 0
    invoice_two.save!

    # None of these should be included
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_factoring, summa: 53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_two.tapvm)

    # overdue_accounts_receivable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 53.39, response[:overdue_accounts_receivable].to_f

    # Third invoice is unpaid but due today, should not be included
    # as we should include invoices between week_start and yesterday
    invoice_three = invoice_one.dup
    invoice_three.erpcm = Date.today
    invoice_three.mapvm = 0
    invoice_three.save!

    # None of these should be included
    invoice_three.accounting_rows.create!(tilino: @receivable_regular, summa: 11, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @receivable_factoring, summa: 22, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @receivable_concern, summa: 33, tapvm: invoice_three.tapvm)

    # overdue_accounts_receivable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 53.39, response[:overdue_accounts_receivable].to_f, "Weekstart #{Date.today.beginning_of_week} Today #{Date.today} Duedate #{invoice_three.erpcm} Yesterday #{Date.yesterday}"

    # Fourth invoice is paid yesterday, should not be included
    invoice_four = invoice_one.dup
    invoice_four.erpcm = Date.today - 1.day
    invoice_four.mapvm = Date.today - 1.day
    invoice_four.save!

    # None of these should be included
    invoice_four.accounting_rows.create!(tilino: @receivable_regular, summa: 53.39, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_factoring, summa: 53.39, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_four.tapvm)

    # overdue_accounts_receivable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 53.39, response[:overdue_accounts_receivable].to_f
  end

  test 'weekly sales' do
    # Weekly sales are grouped per week, we'll test the first/current week
    # We must travel to friday, since factoring accounts for "yesterday".
    # Otherwise these test would not work on mondays.
    this_friday = Date.today.beginning_of_week.advance(days: 4)
    travel_to this_friday

    # Let's save one invoice and delete the rest
    invoice_one = heads(:si_one).dup
    Head::SalesInvoice.delete_all

    # First is unpaid, within current week, should be included
    invoice_one.erpcm = Date.today
    invoice_one.mapvm = 0
    invoice_one.alatila = 'X'
    invoice_one.save!

    # Only regular accounting rows should be included
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: 153.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_concern, summa: 543.39, tapvm: invoice_one.tapvm)

    # sales should be 153.39
    response = RevenueExpenditureReport.new(1).data
    assert_equal 153.39, response[:weekly][0][:sales].to_f

    # Second invoice unpaid, but due last week, should not be included
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.tapvm = Date.today - 2.weeks
    invoice_two.mapvm = 0
    invoice_two.save!

    # None of these should be included
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_factoring, summa: 53.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_two.tapvm)

    # sales should be 153.39
    response = RevenueExpenditureReport.new(1).data
    assert_equal 153.39, response[:weekly][0][:sales].to_f

    # Third invoice is overdue factoring
    # only 30% of account row's sum is added
    # overdue date is on current week, but event date is not
    invoice_three = invoice_one.dup
    invoice_three.erpcm = Date.today - 1.day
    invoice_three.tapvm = Date.today - 1.week
    invoice_three.save!

    # 30% of factoring rows should be included (222 * 0.3 = 66.6)
    invoice_three.accounting_rows.create!(tilino: @receivable_factoring, summa: 222, tapvm: invoice_three.tapvm)
    invoice_three.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_three.tapvm)

    # sales should be 153.39 + 66.6
    response = RevenueExpenditureReport.new(1).data
    assert_equal 219.99, response[:weekly][0][:sales].to_f

    # Fourth invoice is factoring, due 1 week from now. event date is yesterday
    # we should include 70% of factoring rows based on event date
    invoice_four = invoice_one.dup
    invoice_four.erpcm = Date.today + 1.week
    invoice_four.tapvm = Date.today - 2.days
    invoice_four.save!

    # 70% of facatoring rows should be included (42 * 0.7 = 29.4) * 2 = 58.8
    invoice_four.accounting_rows.create!(tilino: @receivable_factoring, summa: 42, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_factoring, summa: 42, tapvm: invoice_four.tapvm)
    invoice_four.accounting_rows.create!(tilino: @receivable_concern, summa: 53.39, tapvm: invoice_four.tapvm)

    # sales should be 153.39 + 66.6 + 58.8
    response = RevenueExpenditureReport.new(1).data
    assert_equal 278.79, response[:weekly][0][:sales].to_f
  end

  test 'weekly purchases' do
    # weekly purchases consists of
    # - purchases
    # - alternative expenditures

    # Let's save one invoice and delete the rest
    invoice_one = heads(:pi_H).dup
    Head::PurchaseInvoice.delete_all

    # Let's save one keyword and delete the rest
    keyword_one = keywords(:weekly_alternative_expenditure_one).dup
    Keyword::RevenueExpenditureReportData.delete_all

    # First invoice is unpaid within current week
    invoice_one.erpcm = Date.today
    invoice_one.mapvm = 0
    invoice_one.alatila = 'X'
    invoice_one.save!

    # Only regular accounting rows should be included (300.0)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -153.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -146.61, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_concern, summa: -543.39, tapvm: invoice_one.tapvm)

    # We should have 300
    response = RevenueExpenditureReport.new(1).data
    assert_equal 300, response[:weekly][0][:purchases].to_f

    # Second invoice is unpaid, outside of current week
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.save!

    # Nothing should be included
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -153.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -146.61, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_concern, summa: -543.39, tapvm: invoice_two.tapvm)

    # We should have 300 + 0
    response = RevenueExpenditureReport.new(1).data
    assert_equal 300, response[:weekly][0][:purchases].to_f

    current_week = "#{Date.today.cweek} / #{Date.today.year}"
    assert_equal current_week, response[:weekly][0][:week]

    # Lets add one alternative expenditure for current week
    # this should be added to purchases
    keyword_one.selite = current_week
    keyword_one.selitetark_2 = '100'
    keyword_one.save!

    # Lets add another one alternative expenditure for next week
    # Should not be added to purchases
    keyword_two = keyword_one.dup
    keyword_two.selite = "#{1.week.from_now.to_date.cweek} / #{1.week.from_now.year}"
    keyword_two.selitetark_2 = '100'
    keyword_two.save!

    # we should have 300 + 100
    response = RevenueExpenditureReport.new(1).data
    assert_equal 400, response[:weekly][0][:purchases].to_f
  end

  test 'weekly company group accounts receivable' do
    # Let's save one invoice and delete the rest
    invoice_one = heads(:si_one).dup
    Head::SalesInvoice.delete_all

    # First is unpaid and within current week
    invoice_one.erpcm = Date.today
    invoice_one.mapvm = 0
    invoice_one.alatila = 'X'
    invoice_one.save!

    # Only concern rows should be included
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: 300.05, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_regular, summa: 100.15, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @receivable_concern, summa: 200.20, tapvm: invoice_one.tapvm)

    # we should have 200.20
    response = RevenueExpenditureReport.new(1).data
    assert_equal 200.20, response[:weekly][0][:concern_accounts_receivable].to_f

    # Second invoice is outside of current week
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.save!

    # none of this should be included
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 300.05, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_regular, summa: 100.15, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @receivable_concern, summa: 200.20, tapvm: invoice_two.tapvm)

    # we should have 200.20
    response = RevenueExpenditureReport.new(1).data
    assert_equal 200.20, response[:weekly][0][:concern_accounts_receivable].to_f
  end

  test 'weekly company group accounts payable' do
    # Let's save one invoice and delete the rest
    invoice_one = heads(:pi_H).dup
    Head::PurchaseInvoice.delete_all

    # First invoice is sent, unpaid, and due this week
    invoice_one.erpcm = Date.today
    invoice_one.mapvm = 0
    invoice_one.alatila = 'X'
    invoice_one.save!

    # Concern accounting rows should be included (666,73)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -153.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_regular, summa: -146.61, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_concern, summa: -543.39, tapvm: invoice_one.tapvm)
    invoice_one.accounting_rows.create!(tilino: @payable_concern, summa: -123.34, tapvm: invoice_one.tapvm)

    # concern accounts payable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 666.73, response[:weekly][0][:concern_accounts_payable].to_f

    # Second invoice is sent, unpaid, but outside of current week
    invoice_two = invoice_one.dup
    invoice_two.erpcm = Date.today - 1.week
    invoice_two.save!

    # Nothing should be included
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -153.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_regular, summa: -146.61, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_concern, summa: -543.39, tapvm: invoice_two.tapvm)
    invoice_two.accounting_rows.create!(tilino: @payable_concern, summa: -123.34, tapvm: invoice_two.tapvm)

    # concern accounts payable should include invoice one
    response = RevenueExpenditureReport.new(1).data
    assert_equal 666.73, response[:weekly][0][:concern_accounts_payable].to_f
  end

  test 'weekly alternative expenditures' do
    # Lets add one alternative expenditure for current week
    keyword_one = keywords(:weekly_alternative_expenditure_one)
    keyword_one.selite = "#{Date.today.cweek} / #{Date.today.year}"
    keyword_one.selitetark_2 = '53.39'
    keyword_one.save!

    # Should not sum this keyword's amount
    keyword_two = keyword_one.dup
    keyword_two.selite = "#{1.week.from_now.to_date.cweek} / #{1.week.from_now.year}"
    keyword_two.selitetark_2 = '100'
    keyword_two.save!

    response = RevenueExpenditureReport.new(1).data
    assert_equal 53.39, response[:weekly][0][:alternative_expenditures][0][:amount].to_f
  end

  test 'should return data per week' do
    # Let's travel to a static date, so we know how many weeks to expect
    travel_to Date.parse '2015-08-14'

    response = RevenueExpenditureReport.new(1).data
    assert_equal 5, response[:weekly].count

    response = RevenueExpenditureReport.new(2).data
    assert_equal 9, response[:weekly].count
  end
end
