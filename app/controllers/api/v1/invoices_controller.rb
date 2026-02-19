module Api
  module V1
    class InvoicesController < ApplicationController
      # skip_before_action :verify_authenticity_token # API mode skips this by default usually, but if needed

      def index
        invoices = Invoice.includes(:account).order(created_at: :desc).limit(50)
        render json: invoices, include: [ :invoice_lines, :extraction ]
      end

      def create
        # Assuming file upload or URL
        # For MVP optimization, we might accept a URL or just a mock
        # If file upload, Rails handles it via params

        # Determine account (mock for now or from header)
        # We need a default account since we don't have auth yet.
        account = Account.first_or_create!(name: "Demo Account")

        invoice = account.invoices.new(invoice_params)

        if invoice.save
          ProcessInvoiceJob.perform_later(invoice.id)
          render json: invoice, status: :created
        else
          render json: { errors: invoice.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        invoice = Invoice.find(params[:id])
        render json: invoice, include: [ :invoice_lines, :extraction ]
      end

      private

      def invoice_params
        params.permit(:file_url, :notes)
      end
    end
  end
end
