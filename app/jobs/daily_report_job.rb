class DailyReportJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    return unless ResendDailyReport.configured?

    ResendDailyReport.deliver!(date: Date.parse(date.to_s))
  end
end
