class DailySequence < ApplicationRecord
  KINDS = %w[bill kot].freeze

  validates :service_date, :kind, :last_number, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :kind, uniqueness: { scope: :service_date }
  validates :last_number, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.next!(kind, date:)
    kind = kind.to_s
    raise ArgumentError, "Unknown sequence: #{kind}" unless KINDS.include?(kind)

    retries = 0
    begin
      transaction do
        record = where(service_date: date, kind: kind).lock.first
        if record.nil?
          record = create!(service_date: date, kind: kind, last_number: 0)
        end
        record.increment!(:last_number)
        record.last_number
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      retries += 1
      retry if retries < 3
      raise
    end
  end
end
