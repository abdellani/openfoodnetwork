# frozen_string_literal: true

module Reporting
  module Reports
    module Customers
      class Base < ReportTemplate
        def query_result
          filter(Spree::Order.managed_by(@user)
            .distributed_by_user(@user)
            .complete.not_state(:canceled)
            .order(:id))
            .group_by do |order|
            {
              customer_id: order.customer_id || order.email,
              hub_id: order.distributor_id,
            }
          end.values
        end

        # rubocop:disable Metrics/AbcSize
        def columns
          {
            first_name: proc { |orders| last_completed_order(orders).billing_address.firstname },
            last_name: proc { |orders| last_completed_order(orders).billing_address.lastname },
            billing_address: proc { |orders|
                               last_completed_order(orders).billing_address.address_and_city
                             },
            email: proc { |orders| last_completed_order(orders).email },
            phone: proc { |orders| last_completed_order(orders).billing_address.phone },
            hub: proc { |orders| last_completed_order(orders).distributor&.name },
            hub_address: proc { |orders|
                           last_completed_order(orders).distributor&.address&.address_and_city
                         },
            shipping_method: proc { |orders| last_completed_order(orders).shipping_method&.name },
            total_orders: proc { |orders| orders.count },
            total_incl_tax: proc { |orders| orders.sum(&:total) },
            last_completed_order_date: proc { |orders| last_completed_order_date(orders) },
          }
        end
        # rubocop:enable Metrics/AbcSize

        def filter(orders)
          filter_to_completed_at filter_to_distributor filter_to_order_cycle orders
        end

        def skip_duplicate_rows?
          true
        end

        private

        def filter_to_completed_at(orders)
          min = params.dig(:q, :completed_at_gt)
          max = params.dig(:q, :completed_at_lt)

          return orders if min.blank? || max.blank?

          if client_time_zone.present?
            min = convert_to_client_time_zone(min)
            max = convert_to_client_time_zone(max)
          end
          orders.where(completed_at: [min..max])
        end

        def filter_to_distributor(orders)
          if params[:distributor_id].to_i > 0
            orders.where(distributor_id: params[:distributor_id])
          else
            orders
          end
        end

        def filter_to_order_cycle(orders)
          if params[:order_cycle_id].to_i > 0
            orders.where(order_cycle_id: params[:order_cycle_id])
          else
            orders
          end
        end

        def last_completed_order(orders)
          orders.max_by(&:completed_at)
        end

        def last_completed_order_date(orders)
          last_completed_order(orders).completed_at&.to_date
        end

        def convert_to_client_time_zone(datetime)
          DateTime.parse(datetime).change(offset: utc_offset)
        end

        def client_time_zone
          ActiveSupport::TimeZone[params[:time_zone] || ""]
        end

        def utc_offset
          ActiveSupport::TimeZone[client_time_zone].formatted_offset
        end
      end
    end
  end
end
