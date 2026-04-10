"use client";

import Link from "next/link";

import { getDemoUnreadCount } from "@/lib/demo-data";

export function AlertBell() {
  const unreadCount = getDemoUnreadCount();

  return (
    <Link
      href="/alerts"
      className="relative rounded-2xl bg-rose-50 px-3 py-2 text-rose-700 transition-colors hover:bg-rose-100"
    >
      <span className="text-xl">🔔</span>
      {unreadCount > 0 && (
        <span className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-red-600 px-1 text-[10px] font-bold text-white">
          {unreadCount > 9 ? "9+" : unreadCount}
        </span>
      )}
    </Link>
  );
}
