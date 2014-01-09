class TermsOfPayment < ActiveRecord::Base

  include Validators

  belongs_to :company, foreign_key: :yhtio, primary_key: :yhtio

  has_many :customers, foreign_key: :maksuehto
  has_many :invoices, foreign_key: :maksuehto

  validates :rel_pvm,
            :kassa_relpvm,
            :pankkiyhteystiedot,
            :jarjestys, numericality: { only_integer: true }

  validates :jv,
            :kateinen,
            :itsetulostus,
            :jaksotettu,
            :erapvmkasin,
            :kaytossa, presence: true, allow_blank: true, length: { is: 1 }

  validates :teksti, presence: true, allow_blank: false, length: { within: 1..40 }
  validates :factoring, :sallitut_maat, allow_blank: true, length: { within: 1..50 }
  validates :kassa_alepros, numericality: true
  validates :yhtio, presence: true

  validate do |top|
    valid_date :abs_pvm, top
    valid_date :kassa_abspvm, top
  end

  before_create :update_created
  before_update :update_modified
  before_validation :check_if_in_use

  self.table_name = "maksuehto"
  self.primary_key = "tunnus"
  self.record_timestamps = false

  private

    def update_created
      self.luontiaika = Date.today
      self.muutospvm = Date.today
    end

    def update_modified
      self.muutospvm = Date.today
    end

    def check_if_in_use

      if kaytossa?

        cust = customers
        inv_d = invoices.not_delivered
        inv_f = invoices.not_finished

        msg = "HUOM: Maksuehtoa ei voi poistaa, koska se on käytössä"

        errors.add(:base, "#{msg} #{cust.count} asiakkaalla") if cust.present?
        errors.add(:base, "#{msg} #{inv_d.count} toimittamattomalla myyntitilauksella") if inv_d.present?
        errors.add(:base, "#{msg} #{inv_f.count} kesken olevalla myyntitilauksella") if inv_f.present?
      end
    end
end
