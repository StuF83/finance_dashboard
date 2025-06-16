require 'open-uri'

class TransactionCsvService
  def initialize(csv_path = nil)
    @csv_path = csv_path || default_csv_path
  end

  def fetch_and_import
    validate_csv_exists!
    
    Rails.logger.info "Starting CSV import from: #{@csv_path}"
    
    results = Transaction.import_from_csv(@csv_path)
    
    log_import_results(results)
    results
  end

  private

  attr_reader :csv_path

  def default_csv_path
    Rails.root.join('db', 'sample_data', 'monzo_transactions.csv')
  end

  def validate_csv_exists!
    unless File.exist?(@csv_path)
      raise "CSV file not found at: #{@csv_path}"
    end
  end

  def log_import_results(results)
    Rails.logger.info "CSV import completed:"
    Rails.logger.info "  - Imported: #{results[:imported]} transactions"
    Rails.logger.info "  - Skipped: #{results[:skipped]} transactions"
    
    if results[:errors].any?
      Rails.logger.warn "  - Errors encountered:"
      results[:errors].each { |error| Rails.logger.warn "    #{error}" }
    end
  end
end