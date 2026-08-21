class ChecklistEntry < ApplicationRecord
  belongs_to :daily_checklist
  belongs_to :checklist_task

  has_one_attached :photo

  validates :checklist_task_id, uniqueness: { scope: :daily_checklist_id }
  validate :acceptable_photo, if: -> { photo.attached? }

  def toggle!(checked_value)
    update!(
      checked: checked_value,
      checked_at: checked_value ? Time.current : nil
    )
  end

  def checklist_date
    daily_checklist.checklist_date
  end

  private

  def acceptable_photo
    unless photo.blob.content_type.in?(%w[image/jpeg image/jpg image/png image/webp image/heic image/heif])
      errors.add(:photo, "must be a JPEG, PNG, WebP, or HEIC image")
    end

    return if photo.blob.byte_size <= 10.megabytes

    errors.add(:photo, "is too large (max 10 MB)")
  end
end
