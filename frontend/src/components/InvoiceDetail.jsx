import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import axios from 'axios';

const InvoiceDetail = () => {
  const { id } = useParams();
  const [invoice, setInvoice] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchInvoice();
  }, [id]);

  const fetchInvoice = async () => {
    try {
      const response = await axios.get(`/api/v1/invoices/${id}`);
      setInvoice(response.data);
    } catch (err) {
      setError('Failed to fetch invoice details');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="text-center py-8">Loading invoice details...</div>;
  if (error) return <div className="text-center py-8 text-red-500">{error}</div>;
  if (!invoice) return <div className="text-center py-8">Invoice not found</div>;

  return (
    <div className="bg-white shadow-lg rounded-lg overflow-hidden max-w-4xl mx-auto my-8">
      <div className="px-6 py-4 bg-gray-50 border-b border-gray-200 flex justify-between items-center">
        <h2 className="text-2xl font-bold text-gray-800">Invoice Details</h2>
        <Link to="/" className="text-indigo-600 hover:text-indigo-900 font-medium">
          &larr; Back to List
        </Link>
      </div>

      <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <h3 className="text-lg font-semibold text-gray-700 mb-2">General Info</h3>
          <dl className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Vendor</dt>
              <dd className="mt-1 text-sm text-gray-900">{invoice.vendor_name || 'N/A'}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Invoice Number</dt>
              <dd className="mt-1 text-sm text-gray-900">{invoice.invoice_number || 'N/A'}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Date</dt>
              <dd className="mt-1 text-sm text-gray-900">{invoice.invoice_date || 'N/A'}</dd>
            </div>
            <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Due Date</dt>
              <dd className="mt-1 text-sm text-gray-900">{invoice.due_date || 'N/A'}</dd>
            </div>
             <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Status</dt>
              <dd className="mt-1 text-sm text-gray-900">
                <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full 
                  ${invoice.status === 'extracted' ? 'bg-green-100 text-green-800' : 
                    invoice.status === 'error' ? 'bg-red-100 text-red-800' : 
                    'bg-yellow-100 text-yellow-800'}`}>
                  {invoice.status}
                </span>
              </dd>
            </div>
             <div className="sm:col-span-1">
              <dt className="text-sm font-medium text-gray-500">Total Amount</dt>
              <dd className="mt-1 text-sm font-bold text-gray-900">{invoice.currency} {invoice.total_amount}</dd>
            </div>
          </dl>
        </div>

        <div>
           <h3 className="text-lg font-semibold text-gray-700 mb-2">Extraction Meta</h3>
           <dl className="grid grid-cols-1 gap-x-4 gap-y-4">
             <div>
              <dt className="text-sm font-medium text-gray-500">Confidence</dt>
              <dd className="mt-1 text-sm text-gray-900">{(invoice.match_confidence * 100).toFixed(0)}%</dd>
            </div>
             <div>
              <dt className="text-sm font-medium text-gray-500">Processed At</dt>
              <dd className="mt-1 text-sm text-gray-900">{invoice.processed_at ? new Date(invoice.processed_at).toLocaleString() : 'Pending'}</dd>
            </div>
           </dl>
        </div>
      </div>

      <div className="border-t border-gray-200">
        <div className="px-6 py-4">
          <h3 className="text-lg font-semibold text-gray-700 mb-4">Line Items</h3>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                  <th className="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qty</th>
                  <th className="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Unit Price</th>
                  <th className="px-4 py-2 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Total</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {invoice.invoice_lines && invoice.invoice_lines.map((line) => (
                  <tr key={line.id}>
                    <td className="px-4 py-2 text-sm text-gray-900">{line.description}</td>
                    <td className="px-4 py-2 text-sm text-gray-500 text-right">{line.quantity}</td>
                    <td className="px-4 py-2 text-sm text-gray-500 text-right">{line.unit_price}</td>
                    <td className="px-4 py-2 text-sm text-gray-900 text-right font-medium">{line.line_total}</td>
                  </tr>
                ))}
                 {(!invoice.invoice_lines || invoice.invoice_lines.length === 0) && (
                    <tr>
                      <td colSpan="4" className="px-4 py-2 text-center text-sm text-gray-500">No line items extracted.</td>
                    </tr>
                 )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InvoiceDetail;
