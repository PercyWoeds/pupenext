class HuutokauppaMail
  attr_reader :mail

  def initialize(raw_source)
    @mail = Mail.new(raw_source)
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
    case type
    when :offer_accepted,
         :offer_automatically_accepted,
         :purchase_price_paid
      doc = Nokogiri::HTML(@mail.body.to_s.force_encoding(Encoding::UTF_8))
      regex = %r{
        Ostajan\syhteystiedot:\s*(.*$)\s*(.*$)\s*Puhelin:\s*(.*$)\s*Osoite:\s*(.*$)\s*(\d*)\s*
        (.*$)\s*(.*$)
      }x

      doc.content.match(regex)[1]
    end
  end
end
