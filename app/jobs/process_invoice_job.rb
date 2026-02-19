class ProcessInvoiceJob < ApplicationJob
  queue_as :default

  def perform(invoice_id)
    invoice = Invoice.find(invoice_id)
    return unless invoice.status == "uploaded"

    InvoiceProcessor.new.process(invoice)
  end
end
