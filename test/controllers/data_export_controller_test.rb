require 'test_helper'

class DataExportControllerTest < ActionController::TestCase
  fixtures %w(
    keyword/product_information_types
    keyword/product_keyword_types
    keyword/product_parameter_types
    product/keywords
    products
  )

  setup do
    login users(:bob)
  end

  test 'product keywords ui' do
    get :product_keywords
    assert_response :success
  end

  test 'redirect to category selection if submit not pressed' do
    post :product_keywords_generate
    assert_redirected_to product_keyword_export_path
  end

  test 'product keyword export' do
    post :product_keywords_generate, commit: true, format: :xlsx
    assert_response :success
  end

  test 'prodcut keywords excel format' do
    params = {
     commit: true,
     format: :xlsx,
     language: 'fi',
     type: 'parameter',
    }

    post :product_keywords_generate, params
    excel = open_excel(response.body)

    header = ["Tuoteno", "Malliston nimi", "Tuotteen väri"]
    assert_equal header, excel.row(1)

    row = ["hammer123", "Aluminium", " "]
    assert_equal row, excel.row(2)
  end

  private

    def open_excel(response)
      filename = Tempfile.new('spreadsheet').path
      File.open(filename, 'wb') { |file| file.write(response) }

      xlsx = Roo::Spreadsheet.open(filename, extension: :xlsx)

      File.delete(filename)

      xlsx.sheet(0)
    end
end
