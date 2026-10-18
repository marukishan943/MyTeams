import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, ShieldCheck, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export const LoginView: React.FC = () => {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setErrorMessage('Please enter both email and password.');
      return;
    }

    setIsLoading(true);
    setErrorMessage('');

    const res = await login(email, password);
    if (!res.success) {
      setErrorMessage(res.error || 'Authentication failed. Please check credentials.');
    }
    setIsLoading(false);
  };

  const handleQuickDemoLogin = async () => {
    setEmail('admin@myteams.com');
    setPassword('admin123');
    setIsLoading(true);
    setErrorMessage('');
    await login('admin@myteams.com', 'admin123');
    setIsLoading(false);
  };

  return (
    <div className="min-h-screen bg-linear-to-br from-[#1e2837] via-[#243348] to-[#18202c] flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center">
        {/* Brand Icon */}
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[#3949ab] text-white shadow-xl mb-4 font-black text-2xl tracking-tight">
          MT
        </div>
        <h2 className="text-3xl font-extrabold text-white tracking-tight">
          MY TEAMS
        </h2>
        <p className="mt-1 text-sm text-gray-400">
          Field Operations & CRM Admin Portal
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md px-4 sm:px-0">
        <div className="bg-white py-8 px-6 shadow-2xl rounded-2xl sm:px-10 border border-gray-100">
          <div className="mb-6 border-b border-gray-100 pb-4">
            <h3 className="text-lg font-bold text-gray-900">Admin Authentication</h3>
            <p className="text-xs text-gray-500 mt-0.5">
              Sign in to manage Leads, Customers, and Sales orders.
            </p>
          </div>

          {errorMessage && (
            <div className="mb-5 p-3.5 rounded-lg bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-center space-x-2">
              <AlertCircle className="w-4 h-4 shrink-0 text-rose-500" />
              <span>{errorMessage}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-700 mb-1">
                Admin Email Address
              </label>
              <div className="relative rounded-lg shadow-2xs">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                  <Mail className="h-4 w-4" />
                </div>
                <input
                  type="text"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@myteams.com"
                  className="block w-full pl-9 pr-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-hidden focus:ring-2 focus:ring-[#3949ab] focus:border-[#3949ab] transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-700 mb-1">
                Password
              </label>
              <div className="relative rounded-lg shadow-2xs">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-gray-400">
                  <Lock className="h-4 w-4" />
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="block w-full pl-9 pr-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-hidden focus:ring-2 focus:ring-[#3949ab] focus:border-[#3949ab] transition-colors"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full flex justify-center items-center py-2.5 px-4 border border-transparent rounded-lg shadow-sm text-sm font-semibold text-white bg-[#3949ab] hover:bg-[#303f9f] focus:outline-hidden focus:ring-2 focus:ring-offset-2 focus:ring-[#3949ab] transition-colors disabled:opacity-50 cursor-pointer mt-2"
            >
              {isLoading ? (
                <span>Signing in...</span>
              ) : (
                <>
                  <span>Sign In as Admin</span>
                  <ArrowRight className="ml-2 w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Quick Demo Access Button */}
          <div className="mt-6 pt-5 border-t border-gray-100">
            <div className="bg-indigo-50/70 border border-indigo-100 rounded-xl p-3.5 text-center">
              <div className="flex items-center justify-center space-x-1.5 text-indigo-900 font-semibold text-xs mb-1">
                <ShieldCheck className="w-4 h-4 text-[#3949ab]" />
                <span>Instant Admin Test Access</span>
              </div>
              <p className="text-[11px] text-gray-600 mb-2.5">
                Click below to auto-authenticate with pre-configured Admin credentials:
              </p>
              <button
                type="button"
                onClick={handleQuickDemoLogin}
                className="w-full py-1.5 px-3 bg-white border border-[#3949ab] text-[#3949ab] hover:bg-[#3949ab] hover:text-white rounded-lg text-xs font-semibold shadow-2xs transition-all cursor-pointer"
              >
                1-Click Admin Login (admin@myteams.com)
              </button>
            </div>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-gray-400">
          IV SQUARE STRUCTURE INDIA PVT LTD • All Rights Reserved
        </p>
      </div>
    </div>
  );
};
