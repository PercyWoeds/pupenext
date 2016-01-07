class Reports::Commodity
  attr_accessor :company, :start_date, :end_date

  def initialize(company_id:, start_date:, end_date:)
    self.company    = Company.find company_id
    self.start_date = Date.parse start_date.to_s
    self.end_date   = Date.parse end_date.to_s

    Current.company = company
  end

  # This report response is a top down hierarcial representation of commodities:
  # 1. Response contains an array of commodity sum_levels
  # 2. Sum_level contains an array of its accounts
  # 3. Account contains an array of its commodities
  # 4. Commodity contains the required data/calculations
  def data
    Response.new(company: company, date_range: date_range)
  end

  private

    def date_range
      start_date..end_date
    end

end

class Reports::Commodity::Response
  attr_accessor :company, :date_range

  def initialize(company:, date_range:)
    self.company    = company
    self.date_range = date_range
  end

  def sum_levels
    @sum_levels ||= company.sum_level_commodities.map do |level|
      Reports::Commodity::SumLevel.new(sum_level: level, date_range: date_range)
    end
  end

  def deprication_total
    sum_levels.sum &:deprication_total
  end

  def difference_total
    sum_levels.sum &:difference_total
  end

  def btl_total
    sum_levels.sum &:btl_total
  end

  def procurement_amount_total
    sum_levels.sum &:procurement_amount_total
  end

  def opening_deprication_total
    sum_levels.sum &:opening_deprication_total
  end

  def opening_btl_total
    sum_levels.sum &:opening_btl_total
  end

  def closing_deprication_total
    sum_levels.sum &:closing_deprication_total
  end

  def closing_btl_total
    sum_levels.sum &:closing_btl_total
  end
end

class Reports::Commodity::SumLevel
  attr_accessor :sum_level, :date_range

  def initialize(sum_level:, date_range:)
    self.date_range = date_range
    self.sum_level  = sum_level
  end

  def accounts
    @accounts ||= sum_level.accounts.map do |account|
      Reports::Commodity::Account.new(account: account, date_range: date_range)
    end
  end

  def name
    "#{sum_level.taso} - #{sum_level.nimi}"
  end

  def deprication_total
    accounts.sum &:deprication_total
  end

  def difference_total
    accounts.sum &:difference_total
  end

  def btl_total
    accounts.sum &:btl_total
  end

  def procurement_amount_total
    accounts.sum &:procurement_amount_total
  end

  def opening_deprication_total
    accounts.sum &:opening_deprication_total
  end

  def opening_btl_total
    accounts.sum &:opening_btl_total
  end

  def closing_deprication_total
    accounts.sum &:closing_deprication_total
  end

  def closing_btl_total
    accounts.sum &:closing_btl_total
  end
end

class Reports::Commodity::Account
  attr_accessor :account, :date_range

  def initialize(account:, date_range:)
    self.account    = account
    self.date_range = date_range
  end

  def commodities
    @commodities ||= account.commodities.map do |commodity|
      Reports::Commodity::Commodity.new(commodity: commodity, date_range: date_range)
    end
  end

  def name
    "#{account.tilino} - #{account.nimi}"
  end

  def deprication_total
    commodities.sum &:deprication
  end

  def difference_total
    commodities.sum &:difference
  end

  def btl_total
    commodities.sum &:btl
  end

  def procurement_amount_total
    commodities.sum &:procurement_amount
  end

  def opening_deprication_total
    commodities.sum &:opening_deprication
  end

  def opening_btl_total
    commodities.sum &:opening_btl
  end

  def closing_deprication_total
    commodities.sum &:closing_deprication
  end

  def closing_btl_total
    commodities.sum &:closing_btl
  end
end

class Reports::Commodity::Commodity
  attr_accessor :commodity, :date_range

  def initialize(commodity:, date_range:)
    self.commodity  = commodity
    self.date_range = date_range
  end

  def name
    commodity.name
  end

  def procurement_date
    commodity.procurement_date
  end

  def procurement_amount
    commodity.amount
  end

  def opening_deprication
    commodity.bookkeeping_value date_range.first
  end

  def opening_btl
    commodity.btl_value date_range.first
  end

  def closing_deprication
    commodity.bookkeeping_value date_range.last
  end

  def closing_btl
    commodity.btl_value date_range.last
  end

  def deprication
    @deprication ||= begin
      sum = commodity.depreciation_between(date_range.first, date_range.last)
      sum *= -1.to_d unless sum.zero?
      sum
    end
  end

  def difference
    @difference ||= commodity.difference_between date_range.first, date_range.last
  end

  def btl
    @btl ||= commodity.evl_between date_range.first, date_range.last
  end
end
