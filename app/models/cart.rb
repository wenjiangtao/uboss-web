class Cart < ActiveRecord::Base
  has_many   :cart_items, dependent: :destroy
  belongs_to :user
  #has_many   :items, through: :cart_items, source: :product

  def add_product(product, count=1)
    cart_item = cart_items.find_or_initialize_by(product_id: product.id, seller_id: product.user_id)
    cart_item.count += count
    cart_item.save
  end

  def remove_product_from_cart(product_id)
    cart_items.where(product_id: product_id).destroy_all
  end

  def remove_all_products_in_cart
    cart_items.destroy_all
  end

  def change_cart_item_count(product_id, count, current_cart_id)
    return false if count <= 0
    cart_item = CartItem.where("product_id = ? AND cart_id = ?", product_id, current_cart_id).take!
    cart_item.count = count
    cart_item.save
  end

  def total_price(price_attribute)  # "original_price", "present_price"
    cart_items.inject(0){ |sum, item| sum + item.send(price_attribute)*CartItem.where("product_id = ? AND cart_id = ?", item.product_id, id).take!.count }
  end

  def items_split_by_seller
    seller_ids = cart_items.map(&:seller_id).uniq
    items = []
    seller_ids.each { |seller_id| items << {User.find(seller_id).identify => cart_items.where(seller_id: seller_id)} }
    items
  end

  #登录，合并购物车
  def merge_user_cart(user)
    if self.id != user.cart.try(:id)
      user_cart = user.cart
      self.merge_cart(user_cart)
      self.user = user
      user_cart.destroy
      self.save
    end
    self
  end

  def merge_cart(cart)
    cart.cart_items.each { |cart_item| self.add_product(cart_item.product, cart_item.count) }
    self
  end
end
