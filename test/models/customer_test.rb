require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  fixtures %w(
    countries
    currencies
    customer_prices
    customers
    delivery_methods
    keyword/customer_categories
    keyword/customer_subcategories
    keywords
    products
    sales_order/details
    terms_of_payments
    transports
  )

  setup do
    @one                    = customers :stubborn_customer
    @lissu                  = customers :lissu
    @hammer                 = products :hammer
    @helmet                 = products :helmet
    @ski                    = products :ski
    @customer_category_1    = keyword_customer_categories :customer_category_1
    @customer_subcategory_1 = keyword_customer_subcategories :customer_subcategory_1
  end

  test 'fixtures are valid' do
    assert @one.valid?
    assert @lissu.valid?
  end

  test 'relations' do
    assert_equal 2, @one.transports.count
    assert_equal @customer_category_1, @one.category
    assert_equal @customer_subcategory_1, @one.subcategory
    assert_equal delivery_methods(:kaukokiito), @one.delivery_method
    assert @one.prices.count > 0
    assert @one.products.count > 0
    assert_equal "9", @one.sales_details.first.tila
  end

  test 'contract_price?' do
    assert @one.contract_price?(@hammer)
    assert @one.contract_price?(@helmet)

    refute @one.contract_price?(@ski)
  end

  test 'validate chn' do
    @one.chn = '666'
    @one.email = nil
    refute @one.valid?

    @one.email = ""
    refute @one.valid?

    @one.email = 'testi@example.com'
    assert @one.valid?

    @one.chn = '441'
    @one.email = nil
    assert @one.valid?
  end

  test 'category and subcategory' do
    @one.ryhma = 'not valid'
    refute @one.valid?

    @one.ryhma = @customer_subcategory_1.selite
    assert @one.valid?, @one.errors.full_messages

    @one.osasto = 'not valid'
    refute @one.valid?

    @one.osasto = @customer_category_1.selite
    assert @one.valid?, @one.errors.full_messages
  end

end
