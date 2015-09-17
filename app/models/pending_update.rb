class PendingUpdate < ActiveRecord::Base
  include CurrentUser
  include UserDefinedValidations

  belongs_to :pending_updatable, polymorphic: true

  validates :key, presence: true
  validates :value_type, presence: true, inclusion: {
    in: %w(Date DateTime Decimal Float Integer String Text Time Timestamp)
  }

  validate :attributes

  def attributes
    klass = pending_updatable_type.classify.constantize

    pending_updates = PendingUpdate.where pending_updatable_id: pending_updatable_id,
                                          pending_updatable_type: pending_updatable_type

    hash = {}
    pending_updates.each do |attr|
      hash[attr.key] = attr.value
    end

    hash[key] = value

    obj = klass.find pending_updatable_id
    obj.attributes = hash

    errors.add(:value, obj.errors.full_messages.join(', ')) unless obj.valid?
  end
end
