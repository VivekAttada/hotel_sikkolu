class DiningTablesController < ApplicationController
  before_action :require_bill_access!
  before_action :set_dining_table

  def split
    @dining_table.split!
    redirect_to bills_path(bill_date: params[:bill_date].presence || Date.current),
                notice: "#{@dining_table.name} is now two orders: #{@dining_table.name}A and #{@dining_table.name}B. After both bills are paid, #{@dining_table.name} comes back as one table."
  rescue ArgumentError => e
    redirect_to bills_path(bill_date: params[:bill_date].presence || Date.current), alert: e.message
  end

  def merge
    parent = @dining_table.merge!
    redirect_to bills_path(bill_date: params[:bill_date].presence || Date.current),
                notice: "#{parent.name}A and #{parent.name}B merged back into #{parent.name}."
  rescue ArgumentError => e
    redirect_to bills_path(bill_date: params[:bill_date].presence || Date.current), alert: e.message
  end

  private

  def set_dining_table
    @dining_table = DiningTable.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bills_path, alert: "Dining table not found."
  end
end
