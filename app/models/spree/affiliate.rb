module Spree
  class Affiliate < Spree::Base
    attr_accessor :user

    has_many :referred_records
    has_many :transactions, class_name: 'Spree::CommissionTransaction'
    has_many :commissions, class_name: 'Spree::Commission'
    has_many :affiliate_commission_rules, class_name: 'Spree::AffiliateCommissionRule', inverse_of: :affiliate
    has_many :commission_rules, through: :affiliate_commission_rules, class_name: 'Spree::CommissionRule'

    accepts_nested_attributes_for :affiliate_commission_rules

    validates :name, :path, :email, presence: true
    validates :email, :path, uniqueness: { allow_blank: true }
    validates :email, length: { maximum: 254, allow_blank: true }, email: { allow_blank: true }


    before_create :generate_activation_token, :create_user
    after_commit :send_activation_instruction, on: :create

    def referred_users
      referred_records.includes(:user).collect(&:user).compact
    end

    def referred_orders
      referred_records.includes({user: :orders}).collect{|u| u.user.orders }.flatten.compact
    end

    def referred_count
      referred_records.count
    end

    def get_layout
      layout == 'false' ? false : layout
    end

    def self.layout_options
      [
        ["No Layout", "false"],
        ["Spree Application Layout", 'spree/layouts/spree_application'],
        ["Custom Layout Path", nil]
      ]
    end

    def self.lookup_for_partial lookup_context, partial
      lookup_context.template_exists?(partial, ["spree/affiliates"], false)
    end

    private

      def create_user
        @user = Spree::User.find_or_initialize_by(email: email)
        user.spree_roles << Spree::Role.affiliate
        user.save!
      end

      def generate_activation_token
        self.activation_token = SecureRandom.hex(10)
      end

      def send_activation_instruction
        Spree::AffiliateMailer.activation_instruction(email)
      end

  end
end
