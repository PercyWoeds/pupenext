require 'test_helper'

class Administration::DepartureHelperTest < ActionView::TestCase
  test "returns translated departure options valid for collection" do
    assert day_of_the_week_options.is_a? Array

    text = I18n.t 'administration.delivery_methods.departures.day_of_the_week_options.monday', :fi
    assert_equal text, day_of_the_week_options.first.first
    assert_equal 1, day_of_the_week_options.first.second
  end

  test "returns translated terminal area options valid for collection" do
    assert terminal_area_options.is_a? Array

    assert_equal 'Lastauslaituri', terminal_area_options.first.first
    assert_equal 'LASTAUS', terminal_area_options.first.second
  end

  test "returns translated customer category options valid for collection" do
    assert customer_category_options.is_a? Array

    assert_equal 'Täysi-ikäinen', customer_category_options.first.first
    assert_equal '18', customer_category_options.first.second
  end
end
