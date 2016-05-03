class HuutokauppaMail
  attr_reader :mail, :messages

  DELIVERY_PRODUCT_NUMBERS = (90..95).to_a + (90..95).to_a.map { |e| "#{e}MAX" }

  def initialize(raw_source)
    raise 'Current company must be set' unless Current.company
    raise 'Current user must be set'    unless Current.user

    @mail     = Mail.new(raw_source)
    @doc      = Nokogiri::HTML(@mail.body.to_s.force_encoding(Encoding::UTF_8))
    @messages = []
  end

  def type
    case @mail.subject
    when /Nettihuutokauppa on päättynyt/
      :auction_ended
    when /Huutaja noutaa/
      :bidder_picks_up
    when /Toimituksen tarjouspyyntö/
      :delivery_offer_request
    when /Toimitus tilattu/
      :delivery_ordered
    when /Tarjous hyväksytty/
      :offer_accepted
    when /Tarjous automaattisesti hyväksytty/
      :offer_automatically_accepted
    when /Tarjous hylätty/
      :offer_declined
    when /Kauppahinta maksettu/
      :purchase_price_paid
    end
  end

  def customer_name
    customer_info[:name]
  end

  def customer_email
    customer_info[:email]
  end

  def customer_phone
    customer_info[:phone]
  end

  def customer_address
    customer_info[:address]
  end

  def customer_postcode
    customer_info[:postcode]
  end

  def customer_city
    customer_info[:city]
  end

  def customer_country
    customer_info[:country]
  end

  def delivery_name
    delivery_info[:name]
  end

  def delivery_address
    delivery_info[:address]
  end

  def delivery_postcode
    delivery_info[:postcode]
  end

  def delivery_city
    delivery_info[:city]
  end

  def delivery_phone
    delivery_info[:phone]
  end

  def delivery_email
    delivery_info[:email]
  end

  def delivery_price_without_vat
    return unless delivery_price_with_vat

    delivery_price_with_vat - delivery_vat_amount
  end

  def delivery_price_with_vat
    return unless auction_info[:delivery_price_with_vat]

    format_decimal auction_info[:delivery_price_with_vat]
  end

  def delivery_vat_percent
    return unless auction_info[:delivery_vat_percent]

    format_decimal auction_info[:delivery_vat_percent]
  end

  def delivery_vat_amount
    return unless auction_info[:delivery_vat_amount]

    format_decimal auction_info[:delivery_vat_amount]
  end

  def total_price_with_vat
    return auction_price_with_vat unless auction_info[:total_price_with_vat]

    format_decimal auction_info[:total_price_with_vat]
  end

  def auction_id
    subject_info[:auction_id]
  end

  def auction_title
    auction_info[:auction_title]
  end

  def auction_closing_date
    Time.parse(auction_info[:closing_date])
  end

  def auction_price_without_vat
    format_decimal auction_info[:winning_bid]
  end

  def auction_price_with_vat
    format_decimal auction_info[:price]
  end

  def auction_vat_percent
    format_decimal auction_info[:vat]
  end

  def auction_vat_amount
    format_decimal auction_info[:vat_amount]
  end

  def find_customer
    @customer ||= Customer.find_by(email: customer_email) if customer_email
  end

  def create_customer
    return unless customer_name

    customer = Customer.create!(
      email: customer_email,
      gsm: customer_phone,
      kauppatapahtuman_luonne: Keyword::NatureOfTransaction.first.selite,
      nimi: customer_name,
      osoite: customer_address,
      postino: customer_postcode,
      postitp: customer_city,
      ytunnus: auction_id,
    )

    @messages << "Customer #{customer.id} created"

    customer
  end

  def update_customer
    return unless find_customer

    find_customer.update!(
      gsm: customer_phone,
      nimi: customer_name,
      osoite: customer_address,
      postino: customer_postcode,
      postitp: customer_city,
    )

    @messages << "Customer #{find_customer.id} updated"

    true
  end

  def update_or_create_customer
    if find_customer
      @messages << "Customer #{find_customer.id} was found, so updating existing customer info"

      update_customer

      customer = find_customer
    else
      customer = create_customer
    end

    find_draft.update!(customer: customer)

    customer
  end

  def find_draft
    @draft ||= SalesOrder::Draft.find_by!(viesti: auction_id)
  end

  def find_order
    @order ||= SalesOrder::Order.find_by!(viesti: auction_id)
  end

  def update_order_customer_info
    return unless customer_name

    find_draft.update!(
      nimi: customer_name,
      osoite: customer_address,
      postino: customer_postcode,
      postitp: customer_city,
      email: customer_email,
      puh: customer_phone,
      toim_nimi: '',
      toim_nimitark: '',
      toim_osoite: '',
      toim_postino: '',
      toim_postitp: '',
      toim_maa: '',
      toim_puh: '',
      toim_email: '',
    )

    find_draft.detail.update!(
      laskutus_nimi: '',
      laskutus_nimitark: '',
      laskutus_osoite: '',
      laskutus_postino: '',
      laskutus_postitp: '',
      laskutus_maa: '',
    )

    @messages << "Updated order #{find_draft.id} customer info"

    true
  end

  def update_order_delivery_info
    return unless delivery_name

    find_order.update!(
      toim_email: delivery_email,
      toim_nimi: delivery_name,
      toim_osoite: delivery_address,
      toim_postino: delivery_postcode,
      toim_postitp: delivery_city,
      toim_puh: delivery_phone,
    )

    @messages << "Updated order #{find_order.id} delivery_info"

    true
  end

  def update_order_product_info
    row = find_draft.rows.first

    row.update!(
      alv: auction_vat_percent,
      hinta: auction_price_without_vat,
      hinta_alkuperainen: auction_price_without_vat,
      hinta_valuutassa: auction_price_without_vat,
      nimitys: auction_title,
      rivihinta: auction_price_without_vat,
      rivihinta_valuutassa: auction_price_without_vat,
    )

    @messages << "Updated order #{find_draft.id} row #{row.id} product info"

    true
  end

  def create_sales_order
    return unless customer_name

    customer_id = find_customer.try(:id) || create_customer.id

    response = LegacyMethods.pupesoft_function(:luo_myyntitilausotsikko, customer_id: customer_id)
    sales_order_id = response[:sales_order_id]

    SalesOrder::Draft.find(sales_order_id)
  end

  def add_delivery_row
    return unless delivery_price_with_vat && delivery_price_with_vat > 0

    product = Product.where(tuoteno: DELIVERY_PRODUCT_NUMBERS)
                     .where('round(myyntihinta * 1.24, 2) >= ?', delivery_price_with_vat)
                     .order(:myyntihinta)
                     .first!

    response = LegacyMethods.pupesoft_function(:lisaa_rivi, order_id: find_draft.id, product_id: product.id)

    row = find_draft.rows.find(response[:added_row])

    @messages << "Added delivery row #{row.id} for order #{find_draft.id}"

    row
  end

  def update_delivery_method_to_nouto
    find_draft.update!(delivery_method: DeliveryMethod.find_by!(selite: 'Nouto'))

    @messages << "Updated order #{find_draft.id} delivery method to Nouto"

    true
  end

  def update_delivery_method_to_itella_economy_16
    find_order.update!(delivery_method: DeliveryMethod.find_by!(selite: 'Itella Economy 16'))

    @messages << "Updated order #{find_order.id} delivery method to Itella Economy 16"

    true
  end

  def mark_as_done
    response = find_draft.mark_as_done(create_preliminary_invoice: true)

    @messages << "Marked order #{find_order.id} as done"

    response
  end

  private

    def customer_info
      @customer_info ||= begin
        regex = %r{
          Ostajan\syhteystiedot:\s*
          (Yritys:\s*
          (?<company_name>.*$)\s*
          (?<company_id>.*$)\s*)?
          (?<name>.*$)\s*
          (?<email>.*$)\s*
          Puhelin:\s*(?<phone>.*$)\s*
          Osoite:\s*
          (?<address>.*$)\s*
          (?<postcode>\d*)\s*(?<city>.*$)\s*
          (?<country>.*$)
        }x

        extract_info(regex, @doc.content)
      end
    end

    def delivery_info
      @delivery_info ||= begin
        regex = %r{
          Toimitusosoite\s*
          (?<name>.*$)\s*
          (?<address>.*$)\s*
          (?<postcode>\d*)\s*(?<city>.*$)\s*
          (?<phone>.*$)\s*
          (?<email>\S*)
        }x

        extract_info(regex, @doc.content)
      end
    end

    def subject_info
      @subject_info ||= begin
        regex = %r{
          (kohde|kohteen|kohteelle)\s*\#?(?<auction_id>\d*)
        }x

        extract_info(regex, @mail.subject)
      end
    end

    def auction_info
      @auction_info ||= begin
        currency_number = /(\d|[[:space:]])*(\.|\,)?\d*/

        regex = %r{
          (Kohdenumero|Kohde):?\s*\#?(?<auction_id>\d*)\s*
          Otsikkokenttä:\s*(?<auction_title>.*$)\s*
          Päättymisaika:\s*(?<closing_date>.*$)\s*
          Huudettu:\s*(?<winning_bid>#{currency_number}).*$\s*
          (Hintavaraus:.*\s*)?
          Alv-osuus:\s*(?<vat_amount>#{currency_number}).*$\s*
          Summa:\s*(?<price>#{currency_number}).*,\s*
          ALV\s*(?<vat>#{currency_number}).*$\s*

          # Delivery cost and total price. Not always present.
          ((Toimitus|Nouto):\s*(?<delivery_price_with_vat>#{currency_number})\s*\S*\s*
          ALV\s*(?<delivery_vat_percent>#{currency_number})\s*\S*\s*
          ALV-osuus\s*(?<delivery_vat_amount>#{currency_number}).*$\s*
          Yhteensä:\s*(?<total_price_with_vat>#{currency_number}))?
        }ix

        extract_info(regex, @doc.content)
      end
    end

    def format_decimal(value)
      value.to_s.sub(',', '.').gsub(/[[:space:]]+/, '').to_d
    end

    def extract_info(regex, document)
      info = {}

      document.match(regex) do |match|
        info = match.names.each_with_object({}) do |name, hash|
          hash[name.to_sym] = match[name]
        end
      end

      info
    end
end
