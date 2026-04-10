import Link from "next/link";

import { AlertBell } from "@/components/alerts/AlertBell";

const navItems = [
  { href: "/home", label: "Home", icon: "🏠" },
  { href: "/patients", label: "Patients", icon: "👩‍⚕️" },
  { href: "/alerts", label: "Alerts", icon: "🚨" },
  { href: "/epds", label: "EPDS Screening", icon: "🧠" },
  { href: "/analytics", label: "Analytics", icon: "📊" },
];

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen bg-stone-100 text-stone-900">
      <aside className="hidden w-72 flex-col border-r border-stone-200 bg-white lg:flex">
        <div className="border-b border-stone-200 p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.24em] text-rose-600">
                Maternify
              </p>
              <h1 className="mt-2 text-2xl font-bold text-stone-950">
                Clinical Dashboard
              </h1>
              <p className="mt-2 text-sm leading-6 text-stone-500">
                Demo-first provider view for the Nusrat escalation handoff.
              </p>
            </div>
            <AlertBell />
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-4">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-semibold text-stone-600 transition-colors hover:bg-rose-50 hover:text-rose-700"
            >
              <span>{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="border-t border-stone-200 p-4 text-xs leading-5 text-stone-400">
          Demo account: Dr. Fatema
          <br />
          Seeded to match the mobile RED triage + SOS sequence.
        </div>
      </aside>

      <div className="flex min-h-screen flex-1 flex-col">
        <header className="border-b border-stone-200 bg-white/90 px-4 py-4 backdrop-blur lg:hidden">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-rose-600">
                Maternify
              </p>
              <h1 className="text-lg font-bold">Clinical Dashboard</h1>
            </div>
            <AlertBell />
          </div>
        </header>
        <main className="flex-1">{children}</main>
      </div>
    </div>
  );
}
