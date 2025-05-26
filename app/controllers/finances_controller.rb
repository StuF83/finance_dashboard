class FinancesController < ApplicationController
  def index
    # url = "https://docs.google.com/spreadsheets/d/1nyQibHhXhEy2F1ie2_RL7k8RsJYUImff9WhbNiRvV0Q/edit?usp=sharing"
    TransactionCsvService.new.fetch
    render plain: "Fetch complete — check logs"
  end
end
