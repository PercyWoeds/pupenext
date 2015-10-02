require 'test_helper'

class PendingProductUpdatesControllerTest < ActionController::TestCase
  fixtures %w(products product/suppliers suppliers)

  setup do
    login users(:joe)
  end

  test 'should get index' do
    get :index
    assert_response :success

    assert_template :index, "Template should be index"
  end

  test 'should get list' do
    get :list
    assert_response :success
    assert_template :index, "Without pressing submit-button template should be index"
    assert_nil assigns(:products)

    get :list, commit: 'search'
    assert_template :list, "By pressing submit-button template should be list"
    assert_not_nil assigns(:products)

    get :list, { commit: 'search', 'tuotteen_toimittajat.toim_tuoteno' => 'masterhammer' }
    assert_select "td", { text: 'hammer123', count: 1 }
  end
end