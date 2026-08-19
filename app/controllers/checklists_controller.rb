class ChecklistsController < ApplicationController
  def update
    entry = ChecklistEntry.find(params[:id])
    checked_value = params[:checked] == "1"
    entry.toggle!(checked_value)

    redirect_to root_path(tab: "checklist", checklist_date: entry.daily_checklist.checklist_date),
                notice: "Checklist updated."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path(tab: "checklist"), alert: "Checklist entry not found."
  end
end
