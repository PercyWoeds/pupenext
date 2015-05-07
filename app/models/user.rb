class User < BaseModel
  belongs_to :company, foreign_key: :yhtio, primary_key: :yhtio
  has_many :permissions

  def locale
    locales = %w(fi se en de ee)
    locales.include?(kieli) ? kieli : 'fi'
  end

  def can_read?(resource, options = {})
    permissions.read_access(resource, options).present?
  end

  def can_update?(resource, options = {})
    permissions.update_access(resource, options).present?
  end

  def classic_ui?
    kayttoliittyma == 'C' || (kayttoliittyma.blank? && company.classic_ui?)
  end

  # Map old database schema table to User class
  self.table_name = :kuka
  self.primary_key = :tunnus
end
