require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  # Replace this with your real tests.
  test "buying a product" do
    # delete line items and add ruby book fixtures
    #
    LineItem.delete_all
    Order.delete_all
    ruby_book = products(:ruby)

    #
    # User goes to the store
    get "/"
    assert_response :success
    assert_template "index"

    xml_http_request :post, '/line_items', :product_id => ruby_book.id
    assert_response :success

    cart = Cart.find(session[:cart_id])
    assert_equal 1, cart.line_items.size
    assert_equal ruby_book, cart.line_items[0].product

    #
    # checkout
    get "/orders/new"
    assert_response :success
    assert_template "new"

    post_via_redirect "/orders",
      :order => { :name => "Paul Hahn",
                  :address => "123 The Street",
                  :email => "paul@example.com",
                  :pay_type => "Check"}

    assert_response :success
    assert_template "index"
    cart = Cart.find(session[:cart_id])
    assert_equal 0, cart.line_items.size

  #
  #Verify orders in the database
  #
  orders=Order.all
  assert_equal 1, orders.size
  order = orders[0]

  assert_equal "Paul Hahn", order.name
  assert_equal "123 The Street", order.address
  assert_equal "paul@example.com", order.email
  assert_equal "Check", order.pay_type

  assert_equal 1, order.line_items.size
  line_item = order.line_items[0]
  assert_equal ruby_book, line_item.product

  #
  # Verify email
  #
  mail = ActionMailer::Base.deliveries.last
  assert_equal ["paul@example.com"], mail.to
  assert_equal 'Sam Ruby <dog@dwz.mygbiz.com>', mail[:from].value
  assert_equal "Paul's Store Order Confirmation", mail.subject
  end
end
