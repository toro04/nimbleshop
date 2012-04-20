class AdminMailer < ActionMailer::Base

  include ApplicationHelper

  default from: lambda { Shop.first.from_email }

  default_url_options[:host]     = Settings.host_for_email
  default_url_options[:protocol] = 'http'

  def new_order_notification(order_number)
    @order = Order.find_by_number!(order_number)
    @shop = Shop.first
    @payment_date = @order.paid_at

    mail_options = { to: @order.email, subject: "Order ##{order_number} was recently placed" }

    mail(mail_options) do |format|
      format.text { render "admin/mailer/new_order_notification" }
    end
  end

end
