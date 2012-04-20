class PaymentProcessorsController < ApplicationController

  theme :theme_resolver, only: [:new, :create]

  force_ssl :if => lambda { |controller| controller.use_ssl }

  def set_splitable_data
    order = current_order
    product = order.line_items.first.product
    api_notify_url = request.protocol + request.host_with_port + '/payment_notifications/splitable'
  end

  def new
    # If there is only one payment method enabled and that payment method
    # splitable or paypal then just redirect to that page
    if url = payment_method_url
      redirect_to url
    else
      @page_title = 'Make payment'
      @creditcard = Creditcard.new
    end
  end

  def create
    order = current_order

    case params[:payment_choice]
    when 'splitable'
      handler     = Payment::Handler::Splitable.new(order: order)
      error, url  = handler.create_split(request: request)

      if error
        render text: error
      else
        redirect_to url
      end
    else
      address_attrs     = order.final_billing_address.to_credit_card_attributes
      creditcard_attrs  = params[:creditcard].merge(address_attrs)
      @creditcard       = Creditcard.new(creditcard_attrs)
      handler           = Payment::Handler::AuthorizeNet.new(order)

      if handler.send(Shop.first.default_creditcard_action, creditcard: @creditcard)
        redirect_to paid_order_path(id: current_order, payment_method: :credit_card)
      else
        render action: :new
      end
    end
  end

  def use_ssl
    return false if Rails.env.test?
    PaymentMethod.enabled.find { |i| i.use_ssl == 'true' }
  end

  private

    def payment_method_url
      return nil if PaymentMethod.enabled.count != 1

      permalink = PaymentMethod.enabled.first.permalink
      return nil if permalink == 'authorize-net'
      case permalink
      when 'splitable'
        return PaymentMethod::Splitable.first.url(current_order, request)
      when 'paypal-website-payments-standard'
        return PaymentMethod::PaypalWebsitePaymentsStandard.first.url(current_order)
      end
    end


end
