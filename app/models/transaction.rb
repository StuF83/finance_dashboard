# frozen_string_literal: true

class Transaction < ApplicationRecord
  validates :transaction_datetime, presence: true
  validates :amount, presence: true, numericality: true
  validates :description, presence: true, length: { minimum: 1, maximum: 255 }
  validates :category, presence: true
  validates :transaction_type, inclusion: { in: %w[income expense] }

  scope :income, -> { where(transaction_type: "income") }
  scope :expenses, -> { where(transaction_type: "expense") }
  scope :in_date_range, ->(start_date, end_date) { where(transaction_datetime: start_date..end_date) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(transaction_datetime: :desc) }

  before_validation :set_transaction_type
  before_validation :clean_description

  def self.total_income(start_date = nil, end_date = nil)
    scope = income
    scope = scope.in_date_range(start_date, end_date) if start_date && end_date
    scope.sum(:amount)
  end

  def self.total_expenses(start_date = nil, end_date = nil)
    scope = expenses
    scope = scope.in_date_range(start_date, end_date) if start_date && end_date
    scope.sum(:amount).abs
  end

  def self.net_income(start_date = nil, end_date = nil)
    total_income(start_date, end_date) - total_expenses(start_date, end_date)
  end

  def self.spending_by_category(start_date = nil, end_date = nil)
    scope = expenses
    scope = scope.in_date_range(start_date, end_date) if start_date && end_date
    scope.group(:category).sum(:amount).transform_values(&:abs)
  end

  def self.monthly_summary(months = 12)
    start_date = months.months.ago.beginning_of_month

    (0...months).map do |i|
      month_start = (months - i - 1).months.ago.beginning_of_month
      month_end = month_start.end_of_month

      {
        month: month_start.strftime("%b %Y"),
        income: total_income(month_start, month_end),
        expenses: total_expenses(month_start, month_end)
      }
    end
  end

  # CSV Import functionality
  def self.import_from_csv(file_path, options = {})
    TransactionCsvImportService.new(file_path, options).call
  end

  private

  def set_transaction_type
    return if transaction_type.present?

    self.transaction_type = amount.to_f >= 0 ? "income" : "expense"
  end

  def clean_description
    self.description = description.strip.squeeze(" ")
  end
end