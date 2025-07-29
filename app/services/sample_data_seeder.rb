class SampleDataSeeder
  # Development-only service for seeding sample transaction data

  def self.seed_transactions(force: false)
    # Only run in development unless explicitly forced
    unless Rails.env.development? || force
      Rails.logger.warn "SampleDataSeeder: Skipping - not in development environment"
      return { imported: 0, skipped: 0, message: "Skipped - not in development environment" }
    end

    sample_path = Rails.root.join('db', 'sample_data', 'monzo_transactions.csv')

    unless File.exist?(sample_path)
      error_msg = "Sample data file not found at: #{sample_path}"
      Rails.logger.error "SampleDataSeeder: #{error_msg}"
      return { imported: 0, skipped: 0, error: error_msg }
    end

    Rails.logger.info "SampleDataSeeder: Starting import from #{sample_path}"

    # Use the main import service with force_proceed to skip user interaction
    results = TransactionCsvImportService.new(sample_path, force_proceed: true).call

    log_results(results)
    results
  end

  # Convenience method for clearing and reseeding
  def self.reseed_transactions(force: false)
    return unless Rails.env.development? || force

    Rails.logger.info "SampleDataSeeder: Clearing existing transactions"
    Transaction.delete_all

    seed_transactions(force: force)
  end

  private

  def self.log_results(results)
    Rails.logger.info "SampleDataSeeder: Import completed"
    Rails.logger.info "  - Imported: #{results[:imported]} transactions"
    Rails.logger.info "  - Skipped: #{results[:skipped]} transactions"

    if results[:issues_detected]
      Rails.logger.info "  - Issues detected: #{results[:issue_summary].join(', ')}"
    end

    if results[:detailed_errors].any?
      Rails.logger.warn "  - Detailed errors:"
      results[:detailed_errors].each { |error| Rails.logger.warn "    #{error}" }
    end
  end
end
