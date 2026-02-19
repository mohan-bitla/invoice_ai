class InvoiceProcessor
  def initialize
    @client = OpenAI::Client.new(
      # access_token: ENV.fetch("OPEN_AI_ACCESS_TOKEN")
      access_token: ENV.fetch("GEMINI_ACCESS_TOKEN"),
      uri_base: "https://generativelanguage.googleapis.com/v1beta/openai/"
    )
  end

  def process(invoice)
    invoice.update!(status: 'extracting', processed_at: Time.current)

    start_time = Time.current

    # 1. Prepare prompt and file content
    # TODO: Handle PDF file download and conversion to images or text if needed.
    # For now, assuming file_url is accessible or we using a mock/simple text extraction.
    # If using GPT-4o with Vision, we need image URLs or base64.

    prompt = <<~PROMPT
      Extract the following details from the invoice:
      - Vendor Name
      - Invoice Number
      - Invoice Date (YYYY-MM-DD)
      - Due Date (YYYY-MM-DD)
      - Total Amount
      - Currency
      - Line Items (Description, Quantity, Unit Price, Total, SKU)

      Return the response as a valid JSON object.
    PROMPT

    # Placeholder for actual API call which might need file_url or base64
    response = @client.chat(
      parameters: {
        model: "gemini-3-flash-preview",
        messages: [
          { role: "user", content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: invoice.file_url } }
            ]
          }
        ],
        response_format: { type: "json_object" }
      }
    )

    response_content = response.dig("choices", 0, "message", "content")

    # Mocking response for now to allow progress without actual API key/file
    # response_content = mock_response(invoice)

    duration = (Time.current - start_time) * 1000

    if response_content
      data = JSON.parse(response_content)

      ActiveRecord::Base.transaction do
        # Update Invoice
        invoice.update!(
          vendor_name: data['Vendor Name'],
          invoice_number: data['Invoice Number'],
          invoice_date: data['Invoice Date'],
          due_date: data['Due Date'],
          total_amount: data['Total Amount'],
          currency: data['Currency'],
          extracted_data: data,
          status: 'extracted'
        )

        # Create Line Items
        data['Line Items']&.each do |item|
          invoice.invoice_lines.create!(
            description: item['Description'],
            quantity: item['Quantity'],
            unit_price: item['Unit Price'],
            line_total: item['Total'],
            sku: item['SKU']
          )
        end

        # Create Extraction Record
        Extraction.create!(
          invoice: invoice,
          ai_model: 'gpt-4o-mock',
          raw_prompt: prompt,
          raw_response: data,
          status: 'completed',
          duration_ms: duration,
          confidence: 0.95 # Mock
        )
      end
    else
      invoice.update!(status: 'error')
      Extraction.create!(
        invoice: invoice,
        status: 'failed',
        error_message: "Failed to get response from AI"
      )
    end

  rescue StandardError => e
    invoice.update!(status: 'error', notes: e.message)
    Extraction.create!(
      invoice: invoice,
      status: 'failed',
      error_message: e.message
    )
    raise e
  end

  private

  def mock_response(invoice)
    {
      vendor_name: "Test Vendor",
      invoice_number: "INV-#{invoice.id.to_s[0..4].upcase}",
      invoice_date: Date.today.to_s,
      due_date: (Date.today + 30).to_s,
      total_amount: 1000.00,
      currency: "INR",
      line_items: [
        { description: "Item 1", quantity: 2, unit_price: 500.00, total: 1000.00, sku: "SKU123" }
      ]
    }.to_json
  end
end
