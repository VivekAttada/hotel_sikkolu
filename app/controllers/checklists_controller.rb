class ChecklistsController < ApplicationController
  def update
    entry = ChecklistEntry.find(params[:id])
    checked_value = params[:checked] == "1"
    entry.toggle!(checked_value)

    redirect_to root_path(
      tab: "checklist",
      checklist_date: entry.daily_checklist.checklist_date,
      checklist_view: sanitized_view
    ), notice: "Checklist updated for #{entry.daily_checklist.checklist_date.strftime('%d %b %Y')}."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path(tab: "checklist"), alert: "Checklist entry not found."
  end

  def bulk_update
    date = parse_date(params[:checklist_date]) || Date.current
    daily = DailyChecklist.ensure_entries_for(date)
    checked_value = params[:checked] == "1"
    view = sanitized_view

    entries = daily.checklist_entries
      .joins(:checklist_task)
      .merge(ChecklistTask.active_tasks)

    entries = entries.where(checked: false) if view == "pending" && checked_value

    stamped_at = checked_value ? Time.current : nil
    updated = 0
    entries.find_each do |entry|
      entry.update!(checked: checked_value, checked_at: stamped_at)
      updated += 1
    end

    message = if checked_value
      "Marked #{updated} task#{'s' unless updated == 1} as done for #{date.strftime('%d %b %Y')}."
    else
      "Cleared #{updated} task#{'s' unless updated == 1} for #{date.strftime('%d %b %Y')}."
    end

    redirect_to root_path(tab: "checklist", checklist_date: date, checklist_view: view), notice: message
  end

  private

  def sanitized_view
    view = params[:checklist_view].to_s
    %w[all pending].include?(view) ? view : "all"
  end

  def parse_date(value)
    return if value.blank?

    Date.parse(value)
  rescue ArgumentError
    nil
  end
end
