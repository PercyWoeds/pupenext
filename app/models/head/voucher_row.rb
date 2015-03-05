class Head::VoucherRow < ActiveRecord::Base
  with_options foreign_key: :ltunnus, primary_key: :tunnus do |o|
    o.belongs_to :purchase_invoice, class_name: 'Head::PurchaseInvoice'
    o.belongs_to :purchase_order,   class_name: 'Head::PurchaseOrder'
    o.belongs_to :sales_invoice,    class_name: 'Head::SalesInvoice'
    o.belongs_to :sales_order,      class_name: 'Head::SalesOrder'
    o.belongs_to :voucher,          class_name: 'Head::Voucher'
  end

  belongs_to :company, foreign_key: :yhtio, primary_key: :yhtio
  belongs_to :commodity, class_name: 'FixedAssets::Commodity'

  default_scope { where(korjattu: '') }
  scope :locked, -> { where(lukko: 'X') }
  scope :unlocked, -> { where(lukko: '') }

  validates :yhtio, presence: true
  validate :allow_only_open_fiscal_period
  validate :only_one_account_per_commodity, if: :has_commodity_account?

  before_save :defaults

  def account
    company.accounts.find_by(tilino: tilino)
  end

  def counter_entry(account_number)
    # Create a counter entry for self
    row = self.dup
    row.tilino = account_number
    row.summa *= -1
    row.selite += ' vastakirjaus'
    row.save!
  end

  self.table_name = :tiliointi
  self.primary_key = :tunnus

  private

    def defaults
      self.laadittu ||= Date.today
      self.korjausaika ||= Date.today
    end

    def allow_only_open_fiscal_period
      unless company.date_in_open_period?(tapvm)
        errors.add(:base, 'Must be created on an open fiscal period.')
      end
    end

    def only_one_account_per_commodity
      unless commodity.fixed_assets_account == tilino
        errors.add(:base, "Commodity has already a different account selected!")
      end
    end

    def has_commodity_account?
      commodity.try(:fixed_assets_account).present?
    end
end
