require 'test_helper'

class Administration::TransportsControllerTest < ActionController::TestCase
  fixtures %w(transports)

  setup do
    login users(:bob)

    @transport = transports(:three)

    @valid_params = {
      encoding: 'ISO-8859-15',
      filename: 'foo.txt',
      hostname: @transport.hostname,
      password: @transport.password,
      path: @transport.path,
      port: 55,
      transportable_id: @transport.transportable_id,
      username: @transport.username,
    }
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transport" do
    assert_difference('Transport.count') do
      post :create, transport: @valid_params
    end

    assert_redirected_to transports_path
    transport = Transport.last

    assert_equal @valid_params[:encoding],         transport.encoding
    assert_equal @valid_params[:filename],         transport.filename
    assert_equal @valid_params[:hostname],         transport.hostname
    assert_equal @valid_params[:password],         transport.password
    assert_equal @valid_params[:path],             transport.path
    assert_equal @valid_params[:port],             transport.port
    assert_equal @valid_params[:transportable_id], transport.transportable_id
    assert_equal @valid_params[:username],         transport.username
  end

  test "should show transport" do
    get :show, id: @transport
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @transport
    assert_response :success
  end

  test "should update transport" do
    patch :update, id: @transport, transport: @valid_params
    assert_redirected_to transports_path

    @transport.reload

    assert_equal @valid_params[:encoding],         @transport.encoding
    assert_equal @valid_params[:filename],         @transport.filename
    assert_equal @valid_params[:hostname],         @transport.hostname
    assert_equal @valid_params[:password],         @transport.password
    assert_equal @valid_params[:path],             @transport.path
    assert_equal @valid_params[:port],             @transport.port
    assert_equal @valid_params[:transportable_id], @transport.transportable_id
    assert_equal @valid_params[:username],         @transport.username
  end

  test "should destroy transport" do
    assert_difference('Transport.count', -1) do
      delete :destroy, id: @transport
    end

    assert_redirected_to transports_path
  end
end
