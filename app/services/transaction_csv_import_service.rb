# frozen_string_literal: true

class TransactionCsvImportService
  require "csv"

  def initialize(file_path, options = {})
    @file_path = file_path
    @options = options
    @results = { imported: 0, skipped: 0, errors: [] }
  end

  def call
    validate_file_exists!
    import_transactions
    @results
  end

  attr_reader :file_path, :options, :results

  def validate_file_exists!
    raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)
  end

  def import_transactions
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      process_row(row)
    end
  end

  def process_row(row)
    transaction = create_transaction_from_row(row)

    if transaction.persisted?
      results[:imported] += 1
    else
      handle_transaction_errors(transaction)
    end
  rescue => e
    handle_processing_error(e)
  end

  def create_transaction_from_row(row)
    transaction_data = build_transaction_data(row)
    Transaction.create(transaction_data)
  end

  def build_transaction_data(row)
    {
      transaction_datetime: parse_date(row[date_column]),
      amount: parse_amount(row[amount_column]),
      description: build_description(row),
      category: row[:category]&.strip || "Uncategorized",
      account_name: row[:currency]&.strip,
      reference_number: row[:transaction_id]&.strip,
      notes: build_notes(row)
    }.tap do |data|
      # Add any additional CSV columns if present
      data[:category] = row[:category]&.strip if row[:category]
      data[:notes] = row[:notes]&.strip if row[:notes]
    end
  end

  def build_description(row)
    parts = []
    parts << row[:name]&.strip if row[:name].present?
    parts << row[:emoji] if row[:emoji].present?
    parts << row[:description]&.strip if row[:description].present? && row[:description] != row[:name]

    parts.join(" ").strip
  end

  def build_notes(row)
    notes_parts = []
    notes_parts << row[:notes_and_tags]&.strip if row[:notes_and_tags].present?
    notes_parts << "Address: #{row[:address]}" if row[:address].present?
    notes_parts << "Type: #{row[:type]}" if row[:type].present?

    notes_parts.join(" | ")
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    # Handle common date formats
    Date.parse(date_string.to_s)
  rescue ArgumentError
    nil
  end

  def parse_amount(amount_string)
    return 0 if amount_string.blank?

    # Remove currency symbols and commas, handle parentheses for negative amounts
    cleaned = amount_string.to_s.gsub(/[$,]/, "")

    if cleaned.match(/\((.*)\)/)
      -cleaned.gsub(/[()]/, "").to_f
    else
      cleaned.to_f
    end
  end

  def handle_transaction_errors(transaction)
    results[:errors] << "Row #{$.}: #{transaction.errors.full_messages.join(', ')}"
    results[:skipped] += 1
  end

  def handle_processing_error(error)
    results[:errors] << "Row #{$.}: #{error.message}"
    results[:skipped] += 1
  end

  # Column mapping methods - can be customized via options
  def date_column
    options[:date_column] || :date
  end

  def amount_column
    options[:amount_column] || :amount
  end

  def description_column
    options[:description_column] || :name
  end
end
