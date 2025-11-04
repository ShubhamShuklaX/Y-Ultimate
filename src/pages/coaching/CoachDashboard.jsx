// src/pages/coaching/CoachDashboard.jsx
import React, { useEffect, useState } from "react";
import { fetchCoachDashboard } from "@/lib/coachApi";

// Use the same icon family as your tournament pages
import {
  Star,
  User,
  FileText,
  CalendarDays,
  CheckCircle,
  PlusSquare
} from "lucide-react";

function StatCard({ title, count, subtitle, Icon }) {
  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-md p-4 flex items-center justify-between">
      <div>
        <p className="text-sm text-gray-500">{title}</p>
        <div className="mt-2 text-2xl font-semibold text-gray-900">{count}</div>
        <p className="mt-1 text-sm text-gray-400">{subtitle}</p>
      </div>

      <div className="ml-4">
        <div className="bg-indigo-50 rounded-md p-2 flex items-center justify-center border border-indigo-100 w-10 h-10">
          <Icon className="w-5 h-5 text-indigo-600" />
        </div>
      </div>
    </div>
  );
}

function QuickAction({ title, subtitle, Icon, onClick }) {
  return (
    <button
      onClick={onClick}
      className="flex-1 text-left bg-white rounded-xl border border-gray-100 p-3 hover:shadow-md transition flex items-center gap-4"
    >
      <div className="w-10 h-10 rounded-lg bg-gray-50 flex items-center justify-center border">
        <Icon className="w-5 h-5 text-gray-800" />
      </div>
      <div>
        <div className="font-medium text-gray-900 text-sm">{title}</div>
        {subtitle && <div className="text-xs text-gray-400 mt-1">{subtitle}</div>}
      </div>
    </button>
  );
}

function CardWrapper({ title, children }) {
  return (
    <div className="bg-white rounded-2xl border border-gray-200 p-4 shadow-md">
      {title && <h3 className="font-semibold text-base mb-3">{title}</h3>}
      {children}
    </div>
  );
}

export default function CoachDashboard() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;
    async function load() {
      setLoading(true);
      const d = await fetchCoachDashboard();
      if (!mounted) return;
      setData(d);
      setLoading(false);
    }
    load();
    return () => (mounted = false);
  }, []);

  if (loading || !data) {
    return (
      <div className="p-6">
        <div className="text-lg font-semibold mb-3">Coach Dashboard</div>
        <div className="animate-pulse">
          <div className="h-5 w-1/3 bg-gray-200 rounded mb-4" />
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="h-24 bg-gray-200 rounded" />
            <div className="h-24 bg-gray-200 rounded" />
            <div className="h-24 bg-gray-200 rounded" />
            <div className="h-24 bg-gray-200 rounded" />
          </div>
        </div>
      </div>
    );
  }

  const {
    activePrograms,
    enrolledChildren,
    pendingAssessments,
    upcomingSessions,
    recentPrograms,
    coachWorkload
  } = data;

  return (
    <div className="min-h-screen bg-gray-50">
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Welcome back, Coach! 👋</h1>
          <p className="text-gray-500 mt-1">Manage your sessions, attendance and assessments.</p>
        </div>

        {/* top stat cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <StatCard
            title="Active Programs"
            count={activePrograms}
            subtitle="Currently running"
            Icon={Star}
          />
          <StatCard
            title="Enrolled Children"
            count={enrolledChildren}
            subtitle="Across your programs"
            Icon={User}
          />
          <StatCard
            title="Pending Assessments"
            count={pendingAssessments}
            subtitle="Need entry"
            Icon={FileText}
          />
          <StatCard
            title="Upcoming Sessions"
            count={upcomingSessions}
            subtitle="Next 7 days"
            Icon={CalendarDays}
          />
        </div>

        {/* quick actions */}
        <CardWrapper title="Quick Actions">
          <p className="text-gray-400 mb-4">Common tasks for your role</p>
          <div className="flex flex-col md:flex-row gap-3">
            <QuickAction
              title="Start Attendance"
              subtitle="Mark attendance for a session"
              Icon={CheckCircle}
              onClick={() => window.location.assign("/coaching/sessions")}
            />
            <QuickAction
              title="Add Assessment"
              subtitle="Enter LSAS scores"
              Icon={FileText}
              onClick={() => window.location.assign("/coaching/assessments")}
            />
            <QuickAction
              title="New Session"
              subtitle="Create a coaching session"
              Icon={PlusSquare}
              onClick={() => window.location.assign("/coaching/sessions/create")}
            />
          </div>
        </CardWrapper>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mt-6">
          <div className="space-y-4">
            <CardWrapper title="Coach Workload">
              <p className="text-sm text-gray-500 mb-3">Sessions assigned to you this week and hours</p>
              <div className="space-y-2">
                {coachWorkload.map((c) => (
                  <div key={c.coach} className="flex items-center justify-between p-3 border rounded-md">
                    <div>
                      <div className="font-medium text-sm">{c.coachName}</div>
                      <div className="text-xs text-gray-400">{c.sessions} sessions • {c.hours} hrs</div>
                    </div>
                    <div className="text-indigo-600 font-semibold text-sm">{Math.round(c.utilization)}%</div>
                  </div>
                ))}
              </div>
            </CardWrapper>

            <CardWrapper title="Recent Programs">
              <p className="text-sm text-gray-500 mb-3">Latest coaching programs & batches</p>
              <div className="grid gap-2">
                {recentPrograms.length === 0 && (
                  <div className="text-center py-8 text-gray-400">
                    <Star className="w-10 h-10 mx-auto mb-3 text-gray-400" />
                    <div className="font-medium">No programs yet</div>
                    <div className="text-sm">Create a program to get started</div>
                  </div>
                )}
                {recentPrograms.map((p) => (
                  <div key={p.id} className="p-3 bg-gray-50 rounded-md flex items-start gap-3">
                    <div className="w-10 h-10 rounded-lg bg-white flex items-center justify-center border">
                      <div className="text-indigo-600 font-bold">{p.abbr}</div>
                    </div>
                    <div>
                      <div className="font-medium text-sm">{p.name}</div>
                      <div className="text-xs text-gray-400">{p.site} · {p.children} children</div>
                    </div>
                  </div>
                ))}
              </div>
            </CardWrapper>
          </div>

          <div className="space-y-4">
            <CardWrapper title="Attendance Snapshot">
              <p className="text-sm text-gray-500 mb-3">Summary of today’s sessions</p>
              <div className="grid gap-2">
                {data.attendanceSnapshot.map((s) => (
                  <div key={s.session_id} className="flex items-center justify-between p-3 border rounded-md">
                    <div>
                      <div className="font-medium text-sm">{s.title}</div>
                      <div className="text-xs text-gray-400">{s.site} · {s.time}</div>
                    </div>
                    <div className="text-sm">
                      <div className="font-semibold text-sm">{s.present}/{s.total}</div>
                      <div className="text-xs text-gray-400">Present</div>
                    </div>
                  </div>
                ))}
              </div>
            </CardWrapper>

            <CardWrapper title="Quick Reports">
              <p className="text-sm text-gray-500 mb-3">Useful exports for managers</p>
              <div className="flex gap-3 flex-wrap">
                <button className="px-3 py-2 rounded-md bg-indigo-50 text-indigo-700 font-medium border text-sm">Export Attendance</button>
                <button className="px-3 py-2 rounded-md bg-indigo-50 text-indigo-700 font-medium border text-sm">Export LSAS</button>
                <button className="px-3 py-2 rounded-md bg-indigo-50 text-indigo-700 font-medium border text-sm">Coach Hours</button>
              </div>
            </CardWrapper>
          </div>
        </div>
      </main>
    </div>
  );
}
