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

  def categories
    # Parse date range from params (default to current month)
    @date_range = parse_date_range(params[:date_range])
    @transaction_type = params[:transaction_type] || "expense"
    @min_amount = params[:min_amount]&.to_f || 0
    # Get category breakdown using your existing model methods
    @categories_summary = if @transaction_type == "expense"
      Transaction.spending_by_category(@date_range[:start], @date_range[:end])
    elsif @transaction_type == "income"
      Transaction.income.in_date_range(@date_range[:start], @date_range[:end])
                .group(:category).sum(:amount)
    else
      # All transactions
      Transaction.in_date_range(@date_range[:start], @date_range[:end])
                .group(:category).sum(:amount)
    end
    # Filter by minimum amount
    @categories_summary = @categories_summary.select { |_, amount| amount.abs >= @min_amount }

    # Calculate totals and percentages
    @total_amount = @categories_summary.values.sum.abs
    @categories_with_percentages = @categories_summary.map do |category, amount|
      percentage = @total_amount > 0 ? (amount.abs / @total_amount * 100).round(1) : 0
      [category, { amount: amount.abs, percentage: percentage }]
    end.to_h.sort_by { |_, data| -data[:amount] }.to_h

    # Get transaction count per category
    @transaction_counts = Transaction.in_date_range(@date_range[:start], @date_range[:end])
                                   .where(transaction_type: @transaction_type == 'all' ? ['income', 'expense'] : @transaction_type)
                                   .group(:category).count
  end

  def category_details
    # AJAX endpoint for detailed category view (we'll implement this later)
    render json: { message: "Coming soon!" }
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

  private

  def parse_date_range(date_range_param)
    case date_range_param
    when 'last_month'
      start_date = 1.month.ago.beginning_of_month
      end_date = 1.month.ago.end_of_month
    when 'last_3_months'
      start_date = 3.months.ago.beginning_of_month
      end_date = Date.current.end_of_month
    when 'last_6_months'
      start_date = 6.months.ago.beginning_of_month
      end_date = Date.current.end_of_month
    when 'this_year'
      start_date = Date.current.beginning_of_year
      end_date = Date.current.end_of_year
    else # 'this_month' or default
      start_date = Date.current.beginning_of_month
      end_date = Date.current.end_of_month
    end

    { start: start_date, end: end_date }
    end
end
