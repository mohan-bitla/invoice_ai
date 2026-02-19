import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import InvoiceList from './components/InvoiceList';
import InvoiceUpload from './components/InvoiceUpload';
import InvoiceDetail from './components/InvoiceDetail';

function Dashboard() {
  const [refreshKey, setRefreshKey] = useState(0);

  const handleUploadSuccess = () => {
    setRefreshKey(oldKey => oldKey + 1);
  };

  return (
    <>
      <InvoiceUpload onUploadSuccess={handleUploadSuccess} />
      <div className="mt-8">
        <h2 className="text-xl font-bold mb-4">Processed Invoices</h2>
        <InvoiceList refreshTrigger={refreshKey} />
      </div>
    </>
  );
}

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-gray-100 p-8">
        <div className="max-w-4xl mx-auto">
          <header className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">InvoiceAI Dashboard</h1>
            <p className="text-gray-600">Automated Invoice Processing</p>
          </header>

          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/invoices/:id" element={<InvoiceDetail />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
