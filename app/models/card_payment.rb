class CardPayment < ApplicationRecord
  belongs_to :order
  has_many :transactions, :class_name => "CardTransaction"
  attr_accessor :card_number, :card_verification
  
  def purchase(price)
    response = GATEWAY.purchase(price_in_cents(price), credit_card, purchase_options)
    transactions.create!(:action => "purchase", :amount => price_in_cents(price), :response => response)
    order.update_attribute(:purchased_at, Time.now) if response.success?
    response.success?
  end
  
  def price_in_cents(price)
    (price).to_f
  end

  private
  def purchase_options
    {
      :ip => ip_address,
      :billing_address => {
        :name     => "Ryan Bates",
        :address1 => "123 Main St.",
        :city     => "New York",
        :state    => "NY",
        :country  => "US",
        :zip      => "10001"
      }
    }
  end
  
  def validate_card
    unless credit_card.valid?
      credit_card.errors.full_messages.each do |message|
        errors.add_to_base message
      end
    end
  end
  
  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type               => card_type,
      :number             => card_number,
      :verification_value => card_verification,
      :month              => card_expires_on.month,
      :year               => card_expires_on.year,
      :first_name         => first_name,
      :last_name          => last_name
    )
  end
end
