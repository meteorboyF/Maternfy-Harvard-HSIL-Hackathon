import Link from 'next/link'
import { AlertBell } from '@/components/alerts/AlertBell'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-pink-600">Maternify</h1>
            <p className="text-xs text-gray-500 mt-0.5">Clinical Dashboard</p>
          </div>
          {/* F16 — real-time alert bell */}
          <AlertBell />
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {[
            { href: '/patients',  label: 'Patients',       icon: '👥' },
            { href: '/alerts',    label: 'Alerts',         icon: '🔔' },
            { href: '/epds',      label: 'EPDS Screening', icon: '🧠' },
            { href: '/analytics', label: 'Analytics',      icon: '📊' },
          ].map(({ href, label, icon }) => (
            <Link
              key={href}
              href={href}
              className="flex items-center gap-3 px-3 py-2 rounded-lg text-gray-700 hover:bg-pink-50 hover:text-pink-600 transition-colors"
            >
              <span>{icon}</span>
              <span className="text-sm font-medium">{label}</span>
            </Link>
          ))}
        </nav>
        <div className="p-4 border-t text-xs text-gray-400">
          Maternify v1.0 · Harvard HSIL
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  )
}
