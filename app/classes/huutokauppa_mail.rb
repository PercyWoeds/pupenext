class HuutokauppaMail
  attr_reader :mail

  def initialize(raw_source)
    @mail = Mail.new(raw_source)
    @doc  = Nokogiri::HTML(@mail.body.to_s.force_encoding(Encoding::UTF_8))
  end

  def type
    case @mail.subject
    when /Tarjous automaattisesti hyväksytty/
      :offer_automatically_accepted
    when /Toimituksen tarjouspyyntö/
      :delivery_offer_request
    when /Toimitus tilattu/
      :delivery_ordered
    when /Nettihuutokauppa on päättynyt/
      :auction_ended
    when /Tarjous hyväksytty/
      :offer_accepted
    when /Tarjous hylätty/
      :offer_declined
    when /Kauppahinta maksettu/
      :purchase_price_paid
    when /Huutaja noutaa/
      :bidder_picks_up
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

  private

    def customer_info
      @customer_info ||= begin
        info  = {}
        regex = %r{
          Ostajan\syhteystiedot:\s*(?<name>.*$)\s*(?<email>.*$)\s*Puhelin:\s*(?<phone>.*$)\s*
          Osoite:\s*(?<address>.*$)\s*(?<postcode>\d*)\s*(?<city>.*$)\s*(?<country>.*$)
        }x

        @doc.content.match(regex) do |match|
          info = match.names.each_with_object({}) do |name, hash|
            hash[name.to_sym] = match[name]
          end
        end

        info
      end
    end

    def delivery_info
      @delivery_info ||= begin
        info  = {}
        regex = %r{
          Toimitusosoite\s*(?<name>.*$)\s*(?<address>.*$)\s*(?<postcode>\d*)\s*(?<city>.*$)\s*
          (?<phone>.*$)\s*(?<email>.*$)
        }x

        @doc.content.match(regex) do |match|
          info = match.names.each_with_object({}) do |name, hash|
            hash[name.to_sym] = match[name]
          end
        end

        info
      end
    end
end
