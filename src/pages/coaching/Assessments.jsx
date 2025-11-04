// src/pages/coaching/Assessments.jsx
import React from "react";

export default function Assessments() {
  return (
    <div className="p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold">LSAS Assessments</h1>
        <p className="text-gray-500">Enter and review assessment scores.</p>
      </div>

      <div className="bg-white rounded-2xl p-6 shadow-sm">
        <div className="grid md:grid-cols-2 gap-4">
          <div>
            <label className="text-sm text-gray-600">Child</label>
            <input className="w-full mt-1 p-2 border rounded" placeholder="Search child…" />
          </div>
          <div>
            <label className="text-sm text-gray-600">Assessor</label>
            <input className="w-full mt-1 p-2 border rounded" placeholder="Coach name" />
          </div>

          {["Rules Knowledge & Use", "Fouls & Body Contact", "Fair-Mindedness", "Positive Attitude & Self-Control", "Communication"].map((label, idx) => (
            <div key={idx} className="md:col-span-1">
              <label className="text-sm text-gray-600">{label}</label>
              <select className="w-full mt-1 p-2 border rounded">
                {[0,1,2,3,4].map(n => <option key={n} value={n}>{n}</option>)}
              </select>
            </div>
          ))}

          <div className="md:col-span-2">
            <label className="text-sm text-gray-600">Notes</label>
            <textarea className="w-full mt-1 p-2 border rounded" rows="3" placeholder="Optional comments…" />
          </div>
        </div>

        <button className="mt-5 px-4 py-2 rounded-md bg-indigo-600 text-white">Save Assessment</button>
      </div>
    </div>
  );
}
