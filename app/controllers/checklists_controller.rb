class ChecklistsController < ApplicationController
  before_action :set_entry, only: [ :update, :upload_photo, :destroy_photo ]

  def update
    checked_value = params[:checked] == "1"
    @entry.toggle!(checked_value)

    redirect_to checklist_path(
      checklist_date: @entry.checklist_date,
      checklist_view: sanitized_view
    ), notice: "Checklist updated for #{@entry.checklist_date.strftime('%d %b %Y')}."
  end

  def bulk_update
    date = parse_date(params[:checklist_date]) || Date.current
    date = Date.current if date > Date.current
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

    redirect_to checklist_path(checklist_date: date, checklist_view: view), notice: message
  end

  def upload_photo
    if params[:photo].blank?
      redirect_to checklist_return_path, alert: "Please take or choose a photo to upload."
      return
    end

    @entry.photo.attach(params[:photo])

    if @entry.valid? && @entry.photo.attached?
      redirect_to checklist_return_path,
                  notice: "Photo saved for “#{@entry.checklist_task.title}” on #{@entry.checklist_date.strftime('%d %b %Y')}."
    else
      @entry.photo.purge if @entry.photo.attached?
      redirect_to checklist_return_path,
                  alert: @entry.errors.full_messages.to_sentence.presence || "Could not upload photo."
    end
  end

  def destroy_photo
    @entry.photo.purge if @entry.photo.attached?
    redirect_to checklist_return_path,
                notice: "Photo removed for “#{@entry.checklist_task.title}”."
  end

  private

  def set_entry
    @entry = ChecklistEntry.includes(:daily_checklist, :checklist_task).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to checklist_path, alert: "Checklist entry not found."
  end

  def checklist_return_path
    checklist_path(
      checklist_date: @entry.checklist_date,
      checklist_view: sanitized_view
    )
  end

  def sanitized_view
    view = params[:checklist_view].to_s
    %w[all pending].include?(view) ? view : "all"
  end
end
