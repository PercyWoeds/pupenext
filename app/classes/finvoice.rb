class Finvoice
  include ActionView::Helpers::NumberHelper

  def initialize(invoice_id:, soap: true)
    @invoice = Head::SalesInvoice.find invoice_id
    @soap = soap
    @document = Nokogiri::XML::Builder.new(encoding: 'ISO-8859-15') do |xml|
    end
  end

  def to_xml

    doc.Finvoice(
      "Version" => "2.01",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:noNamespaceSchemaLocation" => "Finvoice2.01.xsd") {

      doc.MessageTransmissionDetails {
        doc.MessageSenderDetails {
          senderdetails
        }
        doc.MessageReceiverDetails {
          receiverdetails
        }
        doc.MessageDetails {
          messagedetails
        }
      }
      doc.SellerPartyDetails {
        sellerpartydetails
      }
      doc.SellerInformationDetails {
        sellerinfodetails
      }
      doc.BuyerPartyDetails {
        buyerpartydetails
      }
      doc.DeliveryDetails {
        deliverydetails
      }
      doc.InvoiceDetails {
        invoicedetails
      }
      doc.PaymentStatusDetails {
        doc.PaymentStatusCode "NOTPAID"
      }
      doc.InvoiceRow {
        doc.ArticleIdentifier "12"
        doc.ArticleName "Nuottivihko"
        doc.DeliveredQuantity("QuantityUnitCode" => "kpl") {
          doc.text("89")
        }
        doc.OrderedQuantity "100"
        doc.InvoicedQuantity("QuantityUnitCode" => "EUR") {
          doc.text("165,54")
        }
        doc.UnitPriceAmount("AmountCurrencyIdentifier" => "EUR") {
          doc.text("1,50")
        }
        doc.RowPositionIdentifier "1"
        doc.RowFreeText "Puuttuvat toimitetaan mahdollisimman pian"
        doc.RowVatRatePercent "24,0"
        doc.RowVatAmount("AmountCurrencyIdentifier" => "EUR") {
          doc.text("32,04")
        }
        doc.RowVatExcludedAmount("AmountCurrencyIdentifier" => "EUR") {
          doc.text("133,50")
        }
      }
      doc.EpiDetails {
        doc.EpiIdentificationDetails {
          doc.EpiDate("Format" => "CCYYMMDD") {
            doc.text("20130814")
          }
          doc.EpiReference "0"
        }
        doc.EpiPartyDetails {
          doc.EpiBfiPartyDetails {
            doc.EpiBfiIdentifier("IdentificationSchemeName" => "BIC") {
              doc.text("BANKFIHH")
            }
          }
          doc.EpiBeneficiaryPartyDetails {
            doc.EpiNameAddressDetails "Pullin Musiikki Oy"
            doc.EpiBei "5647382910"
            doc.EpiAccountID("IdentificationSchemeName" => "IBAN") {
              doc.text("FI3329501800008512")
            }
          }
        }
        doc.EpiPaymentInstructionDetails {
          doc.EpiPaymentInstructionId "192837465"
          doc.EpiRemittanceInfoIdentifier("IdentificationSchemeName" => "ISO") {
            doc.text("RF471234567890")
          }
          doc.EpiInstructedAmount("AmountCurrencyIdentifier" => "EUR") {
            doc.text("165,54")
          }
          doc.EpiCharge("ChargeOption" => "SLEV") {
          }
          doc.EpiDateOptionDate("Format" => "CCYYMMDD") {
            doc.text("20130828")
          }
        }
      }
    }

    procinst = Nokogiri::XML::ProcessingInstruction.new(doc.doc, "xml-stylesheet",
                                                 'href="Finvoice.xsl" type="text/xsl" ')
    doc.doc.root.add_previous_sibling procinst

    return_valid_xml
  end

  private
    def doc
      @document
    end

    def return_valid_xml
      file = Rails.root.join 'vendor', 'assets', 'finvoice', 'Finvoice2.01.xsd'
      xsd = Nokogiri::XML::Schema(File.read(file))

      kala = Nokogiri::XML(doc.to_xml)

      xsd.validate(kala).each do |error|
        puts error.message
      end

      doc.to_xml
    end

    def senderdetails
      sndid = @invoice.company.parameter.finvoice_senderpartyid
      doc.FromIdentifier sndid

      sndint = @invoice.company.parameter.finvoice_senderintermediator
      doc.FromIntermediator sndint
    end

    def receiverdetails
      toid, toint = FinvoiceDetail.receiver_details @invoice
      doc.ToIdentifier toid
      doc.ToIntermediator toint
    end

    def messagedetails
      timenow = Time.now.strftime("%Y%m%d%H%M%S")
      mid = "#{timenow}-#{@invoice.laskunro}";
      tstamp = Time.now.strftime("%Y-%m-%dT%H:%M:%S")

      doc.MessageIdentifier mid
      doc.MessageTimeStamp tstamp
    end

    def sellerpartydetails
      if @invoice.location
        # Invoice has specific location
        y_puhelin   = @invoice.location.puhelin
        y_fax       = @invoice.location.fax
        y_email     = @invoice.location.email
        y_www       = @invoice.location.www
      else
        # Default sender details
        y_puhelin = @invoice.company.puhelin
        y_fax     = @invoice.company.fax
        y_email   = @invoice.company.email
        y_www     = @invoice.company.www
      end

      doc.SellerPartyIdentifier @invoice.company.ytunnus_human
      doc.SellerPartyIdentifierUrlText ""
      doc.SellerOrganisationName @invoice.yhtio_nimi
      doc.SellerOrganisationDepartment ""
      doc.SellerOrganisationDepartment ""
      doc.SellerOrganisationTaxCode @invoice.company.vatnumber_human
      doc.SellerPostalAddressDetails {
        doc.SellerStreetName @invoice.yhtio_osoite
        doc.SellerTownName @invoice.yhtio_postitp
        doc.SellerPostCodeIdentifier @invoice.yhtio_postino
        doc.CountryCode @invoice.yhtio_maa
      }
    end

    def sellerinfodetails

      puts @invoice.terms_of_payment.bank_account_details.inspect

      @invoice.terms_of_payment.bank_account_details.each do |account|
        doc.SellerAccountDetails {
          doc.SellerAccountID("IdentificationSchemeName" => "IBAN") {
            doc.text(account[:iban])
          }
          doc.SellerBic("IdentificationSchemeName" => "BIC") {
            doc.text(account[:bic])
          }
        }
      end
    end

    def buyerpartydetails
      doc.BuyerPartyIdentifier @invoice.ytunnus_human
        doc.BuyerOrganisationName @invoice.nimi
        doc.BuyerOrganisationDepartment ""
        doc.BuyerOrganisationDepartment ""
        doc.BuyerOrganisationTaxCode @invoice.vatnumber_human
        doc.BuyerPostalAddressDetails {
          doc.BuyerStreetName @invoice.osoite
          doc.BuyerTownName @invoice.postitp
          doc.BuyerPostCodeIdentifier @invoice.postino
          doc.CountryCode @invoice.maa
          doc.CountryName @invoice.maa
          doc.BuyerPostOfficeBoxIdentifier ""
        }
    end

    def deliverydetails
      doc.DeliveryPeriodDetails {
        doc.StartDate("Format" => "CCYYMMDD") {
          doc.text(@invoice.deliveryperiod_start.strftime("%Y%m%d"))
        }
        doc.EndDate("Format" => "CCYYMMDD") {
          doc.text(@invoice.deliveryperiod_end.strftime("%Y%m%d"))
        }
      }
      doc.DeliveryMethodText @invoice.toimitustapa
      doc.DeliveryTermsText @invoice.toimitusehto
    end

    def invoicedetails
      if @invoice.credit?
        doc.InvoiceTypeCode "INV02"
        doc.InvoiceTypeText "HYVITYSLASKU"
      else
        doc.InvoiceTypeCode "INV01"
        doc.InvoiceTypeText "LASKU"
      end

      doc.OriginCode "Original"
      doc.InvoiceNumber @invoice.laskunro
      doc.InvoiceDate("Format" => "CCYYMMDD") {
        doc.text(@invoice.tapvm.strftime("%Y%m%d"))
      }
      doc.SellerReferenceIdentifier @invoice.tunnus

      if @invoice.asiakkaan_tilausnumero.strip
        doc.OrderIdentifier @invoice.asiakkaan_tilausnumero
      else
        doc.OrderIdentifier @invoice.viesti
      end

      doc.AgreementIdentifier @invoice.viesti

      doc.InvoiceTotalVatExcludedAmount("AmountCurrencyIdentifier" => @invoice.valkoodi) {
        doc.text(number_to_currency(@invoice.arvo, separator: ",", format: "%n"))
      }
      doc.InvoiceTotalVatAmount("AmountCurrencyIdentifier" => @invoice.valkoodi) {
        alv = (@invoice.summa - @invoice.arvo).round(2)
        doc.text(number_to_currency(alv, separator: ",", format: "%n"))
      }
      doc.InvoiceTotalVatIncludedAmount("AmountCurrencyIdentifier" => @invoice.valkoodi) {
        doc.text(number_to_currency(@invoice.summa, separator: ",", format: "%n"))
      }

      doc.VatSpecificationDetails {
        doc.VatBaseAmount("AmountCurrencyIdentifier" =>  @invoice.valkoodi) {
          doc.text("133,50")
        }
        doc.VatRatePercent "24,0"
        doc.VatRateAmount("AmountCurrencyIdentifier" =>  @invoice.valkoodi) {
          doc.text("32,04")
        }
      }

      doc.PaymentTermsDetails {
        doc.PaymentTermsFreeText "14 päivää netto"
        doc.InvoiceDueDate("Format" => "CCYYMMDD") {
          doc.text("20130828")
        }
        doc.PaymentOverDueFineDetails {
          doc.PaymentOverDueFineFreeText "Viivästyskorko"
          doc.PaymentOverDueFinePercent "7,5"
        }
      }
    end

    def rows
      @invoice.rows.each do |row|
        row.tuoteno
        row.nimitys
      end
    end
end
