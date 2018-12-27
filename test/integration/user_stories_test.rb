require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products
  include ActiveJob::TestHelper
  # test "the truth" do
  #   assert true
  # end
  test "buying a product" do
    start_order_count = Order.count
    ruby_book = products(:ruby)

    get "/"
    assert_response :success
    assert_select 'h1', "Your Pragmatic Catalog"

    post '/line_items', params: {
        product_id: ruby_book.id
    }, xhr: true
    assert_response :success

    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product

    get '/orders/new'
    assert_response :success
    assert_select 'legend', 'Please Enter Your Details'

    perform_enqueued_jobs do
      post "/orders", params: {
          order: {
              name: "yuanchang",
              address: "杨湖镇",
              email: "435252611@qq.com",
              pay_type: "Check"
          }
      }

      follow_redirect!

      assert_response :success

      assert_select 'h1', "Your Pragmatic Catalog"
      cart = Cart.find(session[:cart_id])
      assert_equal 0, cart.line_items.size

      assert_equal start_order_count + 1, Order.count
      order = Order.last

      assert_equal "yuanchang", order.name
      assert_equal "杨湖镇", order.address
      assert_equal "435252611@qq.com", order.email
      assert_equal "Check", order.pay_type

      assert_equal 1, order.line_items.size
      line_item= order.line_items[0]
      assert_equal ruby_book, line_item.product

      mail = ActionMailer::Base.deliveries.last
      assert_equal ["435252611@qq.com"], mail.to
      assert_equal '苑畅<759337828@qq.com>', mail[:from].value
      assert_equal "Pragmatic Order Confirmation", mail.subject

    end
  end
end
