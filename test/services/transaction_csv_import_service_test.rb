require "test_helper"
class TransactionCsvImportServiceTest < ActiveSupport::TestCase
  test "imports a valid CSV file sucessfully" do
    # ARRANGE - Set up test data
    test_file_path = "/home/stuart/Programming/Ruby/finance_dashboard/db/sample_data/monzo_transactions.csv"

    # Verify test file exists
    assert File.exist?(test_file_path), "Test CSV file should exist at #{test_file_path}"

    # Ensure we start with empty database
    Transaction.delete_all

    # ACT - Run the service
    service = TransactionCsvImportService.new(test_file_path)
    results = service.call

    # ASSERT - Check the results
    assert_equal 109, results[:imported], "Should import 109 transactions"
    assert_equal 0, results[:skipped], "Should skip 0 transactions"
    assert_equal false, results[:issues_detected], "Should detect no issues"
    assert_equal true, results[:can_proceed], "Should be able to proceed"
    assert_equal 109, results[:total_processable], "Should have 109 processable transactions"

    # Check transactions were created
    assert_equal 109, Transaction.count, "Should create transactions in database"

    # Check specific transaction details
    first_transaction = Transaction.first
    assert_not_nil first_transaction, "First transaction should exist"
    assert_not_nil first_transaction.reference_number, "Should have a referecne number" 
    assert_not_nil first_transaction.description, "Should have a description"
    assert_not_nil first_transaction.amount, "Should have amount"
    assert_includes [ "incomme", "expense" ], first_transaction.transaction_type, "Should have a valid transaction type"
  end
end
