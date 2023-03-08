class Invoice::OrderSerializer < ActiveModel::Serializer
  attributes :number, :special_instructions, :note, :payment_state, :total, :payment_total, :state,
             :currency, :additional_tax_total, :included_tax_total, :completed_at, :has_taxes_included
  has_one :order_cycle, serializer: Invoice::OrderCycleSerializer
  has_one :customer, serializer: Invoice::CustomerSerializer
  has_one :distributor, serializer: Invoice::EnterpriseSerializer
  has_one :bill_address, serializer: Invoice::AddressSerializer
  has_one :shipping_method, serializer: Invoice::ShippingMethodSerializer
  has_one :ship_address, serializer: Invoice::AddressSerializer
  has_many :sorted_line_items, serializer: Invoice::LineItemSerializer
  has_many :sorted_line_items, serializer: Invoice::LineItemSerializer
  has_many :payments, serializer: Invoice::PaymentSerializer
  has_many :all_eligible_adjustments, serializer: Invoice::AdjustmentSerializer

  def all_eligible_adjustments
    object.all_adjustments.eligible.where.not(originator_type: 'Spree::TaxRate')
  end

  def completed_at
    object.completed_at.to_s
  end
end
