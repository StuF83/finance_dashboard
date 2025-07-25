require "test_helper"
class TransactionCsvImportServiceTest < ActiveSupport::TestCase
  test "imports valid CSV file successfully" do
    # ARRANGE - Set up test data
    test_file_path = test_csv_path("01_monzo_transactions.csv")

    # Verify test file exists
    assert File.exist?(test_file_path), "Test CSV file should exist at #{test_file_path}"

    # Ensure we start with empty database
    Transaction.delete_all

    # ACT - Run the service
    service = TransactionCsvImportService.new(test_file_path)
    results = service.call

    # ASSERT - Check the results
    assert_equal 6, results[:imported], "Should import 6 transactions"
    assert_equal 0, results[:skipped], "Should skip 0 transactions"
    assert_equal false, results[:issues_detected], "Should detect no issues"
    assert_equal true, results[:can_proceed], "Should be able to proceed"
    assert_equal 6, results[:total_processable], "Should have 6 processable transactions"

    # Check transactions were created
    assert_equal 6, Transaction.count, "Should create transactions in database"

    # Check specific transaction details
    first_transaction = Transaction.first
    assert_not_nil first_transaction, "First transaction should exist"
    assert_not_nil first_transaction.reference_number, "Should have a reference number"
    assert_not_nil first_transaction.description, "Should have a description"
    assert_not_nil first_transaction.amount, "Should have amount"
    assert_includes [ "income", "expense" ], first_transaction.transaction_type, "Should have a valid transaction type"
  end

  test "handles existing and new transactions when forced to proceed" do
    setup_test_data

    test_file_path = test_csv_path("02_existing_and_new_transactions.csv")
    assert File.exist?(test_file_path), "Test CSV file should exist at #{test_file_path}"

    service = TransactionCsvImportService.new(test_file_path, force_proceed: true)
    results = service.call

    assert_equal 4, results[:imported], "Should import 4 transactions"
    assert_equal 6, results[:skipped], "Should skip 6 transactions"
    assert_equal true, results[:issues_detected], "Should detect issues"
    assert_equal true, results[:can_proceed], "Should be able to proceed"
    assert_equal 4, results[:total_processable], "Should have 4 processable transactions"
    assert_includes results[:issue_summary], "6 transactions already exist in database", "Issue summary should be populated correctly"
    assert_includes results[:issue_summary], "Transaction validation error", "Issue summary should be populated correctly"

    assert_equal 10, Transaction.count, "Unique transactions should be created in database"
  end

  private

  def test_csv_path(filename)
    Rails.root.join("db", "sample_data", filename)
  end

  def setup_test_data
    Transaction.delete_all
    setup_baseline_transactions
  end

  def setup_baseline_transactions
    base_path = test_csv_path("01_monzo_transactions.csv")
    assert File.exist?(base_path), "Baseline CSV should exist"
    results = TransactionCsvImportService.new(base_path).call
    assert_equal 6, results[:imported], "Baseline setup should import 6 transactions"
  end
end
