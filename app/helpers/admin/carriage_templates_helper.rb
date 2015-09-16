module Admin::CarriageTemplatesHelper

  def total_carriage(product, count, address)
    template = find_template_by_address(product.carriage_template, address)
    total = calculate_price(count, template)
  end

  def calculate_price(count, template)
    balance = count - template.first_item
    first_count = balance > 0 ? template.first_item : count
    extend_count = balance > 0 ? balance : 0

    first_count * template.carriage + extend_count * template.extend_carriage
  end

  #address is provinces name
  def find_template_by_address(carriage_template, address)
    different_areas = carriage_template.different_areas

    area = different_areas.joins(:regions).where(regions: {name: address}).first
    area = different_areas.joins(:regions).where(regions: {name: '其他'}).first if area.blank?
  end
end
