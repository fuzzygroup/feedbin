class BillingEvent < ActiveRecord::Base

  attr_accessor :details

  belongs_to :billable, polymorphic: true

  validates_uniqueness_of :event_id

  before_validation :build_event
  after_commit :process_event, on: :create

  def details
    @details ||= Stripe::StripeObject.construct_from(self.info)
  end

  def build_event
    self.event_type = details.type
    self.event_id = details.id
    self.info = details.as_json

    customer = details.data.object.try(:customer)
    if details.type == "customer.created"
      customer = details.data.object.id
    end

    if customer
      self.billable = User.find_by_customer_id(customer)
    end
  end

  def process_event
    if charge_succeeded?
      UserMailer.delay(queue: :critical).payment_receipt(id)
    end

    if charge_failed?
      UserMailer.delay(queue: :critical).payment_failed(id)
    end

    if subscription_deactivated?
      billable.deactivate
    end

    if subscription_reactivated?
      billable.activate
    end
  end

  def charge_succeeded?
    'charge.succeeded' == event_type
  end

  def charge_failed?
    'invoice.payment_failed' == event_type
  end

  def subscription_deactivated?
    "customer.subscription.updated" == event_type &&
    details.data.object.status == "unpaid"
  end

  def subscription_reactivated?
    "customer.subscription.updated" == event_type &&
    details.data.object.status == "active" &&
    details.data.try(:[], :previous_attributes).try(:[], :status) == "unpaid"
  end

  def invoice
    if self.event_type == "charge.succeeded"
      Rails.cache.fetch("#{self.details.data.object.invoice}") do
        JSON.parse(Stripe::Invoice.retrieve(self.details.data.object.invoice).to_json)
      end
    else
      nil
    end
  end

  def invoice_items
    if self.event_type == "charge.succeeded"
      Rails.cache.fetch("#{self.details.data.object.invoice}:lines") do
        JSON.parse(Stripe::Invoice.retrieve(self.details.data.object.invoice).lines.all(limit: 10).to_json)
      end
    else
      nil
    end
  end

end
