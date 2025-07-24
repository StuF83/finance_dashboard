# frozen_string_literal: true

class TransactionCsvImportService
  require "csv"

  attr_reader :file_path, :options, :results

  def initialize(file_path, options = {})
    @file_path = file_path
    @options = options
    @results = {
      # Import statistics
      imported: 0,
      skipped: 0,

      # Issue detection and user control
      issues_detected: false,
      issue_summary: [],
      detailed_errors: [],
      can_proceed: true,
      total_processable: 0,

      # Duplicate tracking
      duplicate_transactions: []
    }
  end

  def call
    validate_file_exists!
    scan_for_issues
    return results unless results[:can_proceed]
    return results if results[:issues_detected] && !options[:force_proceed]
    import_transactions
    results
  end

  private

  def validate_file_exists!
    raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)
  end

  def scan_for_issues
    csv_transaction_ids = []
    missing_id_count = 0
    total_rows = 0

    # First pass: collect all transaction IDs and count issues
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      total_rows += 1
      transaction_id = row[:transaction_id]&.strip

      if transaction_id.blank?
        missing_id_count += 1
        add_issue("Row #{total_rows}: Missing transaction ID", "Row #{total_rows}: Missing transaction ID - please ensure you're uploading a valid Monzo CSV export")
        next
      end

      csv_transaction_ids << transaction_id
    end

    # Check for duplicates within CSV itself
    csv_duplicates = csv_transaction_ids.group_by(&:itself).select { |_, v| v.size > 1 }.keys
    mark_csv_duplicates_found(csv_duplicates)

    # Check for existing transactions in database
    existing_ids = Transaction.where(reference_number: csv_transaction_ids).pluck(:reference_number)
    mark_duplicates_found(existing_ids)

    # Record missing transaction IDs
    mark_missing_transaction_ids(missing_id_count)

    # Calculate processable transactions
    unique_new_ids = csv_transaction_ids.uniq - existing_ids
    set_processable_count(unique_new_ids.count)
  end

  def import_transactions
    existing_ids = results[:duplicate_transactions] || []

    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      process_row(row, existing_ids)
    end
  end

  def process_row(row, existing_ids = [])
    transaction_id = row[:transaction_id]&.strip

    return if transaction_id.blank?

    if options[:skip_duplicates] && existing_ids.include?(transaction_id)
      results[:skipped] += 1
      return
    end

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
    error_msg = "Row #{$.}: #{transaction.errors.full_messages.join(', ')}"
    add_issue("Transaction validation error", error_msg)
    results[:skipped] += 1
  end

  def handle_processing_error(error)
    error_msg = "Row #{$.}: #{error.message}"
    add_issue("Processing error", error_msg)
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

  # new helper methods
  def add_issue(summary_text, detailed_error = nil)
    results[:issues_detected] = true
    results[:issue_summary] << summary_text unless results[:issue_summary].include?(summary_text)
    results[:detailed_errors] << detailed_error if detailed_error
  end

  def set_processable_count(count)
    results[:total_processable] = count
  end

  def mark_cannot_proceed(reason)
    results[:can_proceed] = false
    add_issue("Cannot proceed: #{reason}")
  end

  def mark_duplicates_found(duplicate_ids)
    results[:duplicate_transactions] = duplicate_ids

    if duplicate_ids.any?
      add_issue("#{duplicate_ids.count} transactions already exist in database")
    end
  end

  def mark_csv_duplicates_found(duplicate_ids)
    if duplicate_ids.any?
      add_issue("#{duplicate_ids.count} duplicate transaction IDs found within CSV file")
    end
  end

  def mark_missing_transaction_ids(count)
    if count > 0
      add_issue("#{count} rows missing transaction IDs")
    end
  end
end
