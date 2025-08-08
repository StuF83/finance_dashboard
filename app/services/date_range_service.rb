class DateRangeService
    def self.parse(date_range_param)
        case date_range_param
        when "last_month"
          start_date = 1.month.ago.beginning_of_month
          end_date = 1.month.ago.end_of_month
        when "last_3_months"
          start_date = 3.months.ago.beginning_of_month
          end_date = Date.current.end_of_month
        when "last_6_months"
          start_date = 6.months.ago.beginning_of_month
          end_date = Date.current.end_of_month
        when "this_year"
          start_date = Date.current.beginning_of_year
          end_date = Date.current.end_of_year
        else # 'this_month' or default
          start_date = Date.current.beginning_of_month
          end_date = Date.current.end_of_month
        end

    { start: start_date, end: end_date }
    end
end
