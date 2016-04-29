class HuutokauppaJob < ActiveJob::Base
  queue_as :huutokauppa

  def perform(id:)
    @incoming_mail = IncomingMail.find(id)

    Current.company = @incoming_mail.company
    Current.user    = Current.company.users.find_by!(kuka: 'admin')

    @huutokauppa_mail = HuutokauppaMail.new(@incoming_mail.raw_source)

    case @huutokauppa_mail.type
    when :offer_accepted, :offer_automatically_accepted
      update_order_customer_and_product_info
    when :purchase_price_paid
      mark_order_as_done_and_set_delivery_method
    end
  end

  private

    def update_order_customer_and_product_info
      customer = @huutokauppa_mail.find_customer || @huutokauppa_mail.create_customer

      @huutokauppa_mail.update_order_customer_info
      @huutokauppa_mail.update_order_product_info

      @incoming_mail.update!(
        processed_at: Time.now,
        status: :ok,
      )
    rescue => e
      @incoming_mail.update!(
        processed_at: Time.now,
        status: :error,
        status_message: e.message,
      )
    end

    def mark_order_as_done_and_set_delivery_method
      @huutokauppa_mail.find_order.update!(
        delivery_method: DeliveryMethod.find_by!(selite: 'Nouto'),
      )
      @huutokauppa_mail.find_order.mark_as_done
    end
end
