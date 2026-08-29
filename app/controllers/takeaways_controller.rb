class TakeawaysController < ApplicationController
  def create
    bill = Bill.create_takeaway!
    redirect_to takeaway_path(bill_id: bill.id), notice: "New takeaway order started."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to takeaway_path, alert: e.record.errors.full_messages.to_sentence.presence || "Could not start takeaway order."
  end
end
