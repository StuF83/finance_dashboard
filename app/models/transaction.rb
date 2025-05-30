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
  scope :recent, -> { order(transaction_date: :desc) }

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
    require "csv"

    results = { imported: 0, skipped: 0, errors: [] }

    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      begin
        transaction = create_from_csv_row(row, options)
        if transaction.persisted?
          results[:imported] += 1
        else
          results[:errors] << "Row #{$.}: #{transaction.errors.full_messages.join(', ')}"
          results[:skipped] += 1
        end
      rescue => e
        results[:errors] << "Row #{$.}: #{e.message}"
        results[:skipped] += 1
      end
    end

    results
  end
  def self.create_from_csv_row(row, options = {})
    transaction_data = {
      transaction_datetime: parse_datetime(row[:date], row[:time]),
      amount: parse_amount(row[:amount]),
      description: build_description(row),
      category: row[:category]&.strip || "Uncategorized",
      account_name: row[:currency]&.strip,
      reference_number: row[:transaction_id]&.strip,
      notes: build_notes(row)
    }

    # Add any additional CSV columns you might have
    transaction_data[:category] = row[:category]&.strip if row[:category]
    transaction_data[:notes] = row[:notes]&.strip if row[:notes]

    create(transaction_data)
  end

  def self.build_description(row)
    parts = []
    if row[:name].present?
      parts << row[:name].strip
      parts << row[:emoji] if row[:emoji].present?
    elsif row[:description].present?
      parts << row[:description]
    else
      parts << "unknown transaction"
    end

    parts.join(" ").strip
  end

  # def self.build_description(row)
  #   name        = row[:name].to_s.strip
  #   description = row[:description].to_s.strip
  #   emoji       = row[:emoji].to_s.strip
  #
  #   if name.present?
  #     [ name, emoji.presence ].compact.join(" ")
  #   elsif description.present?
  #     description
  #   else
  #     "unknown transaction"
  #   end
  # end

  def self.build_notes(row)
    notes_parts = []
    notes_parts << row[:notes_and_tags]&.strip if row[:notes_and_tags].present?
    notes_parts << "Address: #{row[:address]}" if row[:address].present?
    notes_parts << "Type: #{row[:type]}" if row[:type].present?
    notes_parts << "Receipt: #{row[:receipt]}" if row[:receipt].present?  # ✅ Add receipt

    notes_parts.join(" | ")
  end

  private

  def set_transaction_type
    return if transaction_type.present?

    self.transaction_type = amount.to_f >= 0 ? "income" : "expense"
  end
  def clean_description
    self.description = description.strip.squeeze(" ") if description.present?  # ✅ Add safety check
  end

  def self.parse_datetime(date_string, time_string)
    return nil if date_string.blank?

    begin
      date = Date.parse(date_string.to_s)

      if time_string.present?
        # Combine date and time
        time = Time.parse(time_string.to_s)
        DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)
      else
        # Just use date at midnight
        date.to_datetime
      end
    rescue ArgumentError => e
      Rails.logger.warn "Failed to parse datetime: date=#{date_string}, time=#{time_string} - #{e.message}"
      nil
    end
  end

  def self.parse_amount(amount_value)
    amount_value || 0.0
  end
end
