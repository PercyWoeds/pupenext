require 'test_helper'

class Administration::RevenueExpenditureReportDatumControllerTest < ActionController::TestCase
  fixtures %w(keywords)

  setup do
    login users(:bob)
    @data = keywords(:weekly_alternative_expenditure_one)
  end

  test 'should get index' do
    get :index
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @data.tunnus
    assert_response :success

    get :show, id: @data.tunnus
    assert_response :success
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create keyword' do
    params = {
      selite: '36 / 2015',
      selitetark: 'Palkat',
      selitetark_2: 1000,
    }

    assert_difference("Keyword::RevenueExpenditureReportData.count") do
      post :create, data: params
    end

    assert_redirected_to revenue_expenditure_report_datum_index_path
  end
end
