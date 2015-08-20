class Package < BaseModel
  has_many :translations, foreign_key: :selite, primary_key: :tunnus, class_name: 'Keyword::PackageTranslation'
  has_many :package_codes, foreign_key: :pakkaus, primary_key: :tunnus

  validates :pakkaus, presence: true
  validates :pakkauskuvaus, presence: true
  validates :kayttoprosentti, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :leveys, :korkeus, :syvyys, :paino,
            numericality: { greater_than: 0 }, if: :dimensions_are_mandatory?

  after_initialize :initial_values

  enum rahtivapaa_veloitus: {
    add_rack_charge: '',
    no_rack_charge: 'E'
  }

  enum erikoispakkaus: {
    not_special: '',
    special: 'K'
  }

  enum yksin_eraan: {
    combined_parcel: '',
    separate_parcel: 'K'
  }

  self.table_name  = :pakkaus
  self.primary_key = :tunnus

  def dimensions_are_mandatory?
    company.parameter.varastopaikkojen_maarittely == "M"
  end

  private

    def initial_values
      self.kayttoprosentti ||= 100
    end
end
