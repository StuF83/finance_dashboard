require 'open-uri'
require "csv"


class TransactionCsvService
	def initialize
	end

	def fetch
		csv_path = Rails.root.join('lib', 'data', 'monzo_transactions.csv')

		CSV.foreach(csv_path, headers: true) do |row|
		  Rails.logger.info "Parsed row: #{row.to_h.inspect}"
		end
	 end
end