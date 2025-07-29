# frozen_string_literal: true

class TransactionCsvApiService
  # Future service for external API integrations
  # All methods will use TransactionCsvImportService for actual CSV processing

  def initialize(options = {})
    @options = options
  end

  # Placeholder for Google Sheets integration
  def fetch_from_google_sheets(sheet_id)
    raise NotImplementedError, "Google Sheets integration coming soon"

    # Future implementation:
    # 1. Download CSV from Google Sheets API
    # 2. Save to temporary file
    # 3. Call TransactionCsvImportService.new(temp_file_path).call
    # 4. Clean up temp file
    # 5. Return results
  end

  # Placeholder for bank API integration
  def fetch_from_bank_api(bank_config)
    raise NotImplementedError, "Bank API integration coming soon"

    # Future implementation:
    # 1. Connect to bank's API using bank_config
    # 2. Fetch transaction data
    # 3. Convert to CSV format
    # 4. Save to temporary file
    # 5. Call TransactionCsvImportService.new(temp_file_path).call
    # 6. Clean up temp file
    # 7. Return results
  end

  # Placeholder for scheduled imports
  def fetch_from_url(csv_url)
    raise NotImplementedError, "URL-based CSV import coming soon"

    # Future implementation:
    # 1. Download CSV from URL
    # 2. Validate file format
    # 3. Save to temporary file
    # 4. Call TransactionCsvImportService.new(temp_file_path).call
    # 5. Clean up temp file
    # 6. Return results
  end

  private

  attr_reader :options
end
