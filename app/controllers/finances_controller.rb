class FinancesController < ApplicationController
  def index
# Get current month's date range
    start_of_month = Date.current.beginning_of_month
    end_of_month = Date.current.end_of_month
    
    # Calculate summary statistics for current month
    @total_income = Transaction.total_income(start_of_month, end_of_month)
    @total_expenses = Transaction.total_expenses(start_of_month, end_of_month)
    @net_balance = @total_income - @total_expenses
    
    # Get recent transactions (last 10)
    @recent_transactions = Transaction.recent.limit(10)
    
    # Optional: Import CSV for testing (remove this later)
    # TransactionCsvService.new.fetch_and_import if Transaction.count == 0
  end
  
  # Add this method for CSV import functionality later
  def import_csv
    begin
      results = TransactionCsvService.new.fetch_and_import
      redirect_to finances_path, notice: "Successfully imported #{results[:imported]} transactions"
    rescue => e
      redirect_to finances_path, alert: "Import failed: #{e.message}"
    end
  end
end
