require "test_helper"

class FinancesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get finances_url
    assert_response :success
  end
end
