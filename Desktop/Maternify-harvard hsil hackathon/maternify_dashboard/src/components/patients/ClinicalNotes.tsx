"use client";

import { useEffect, useState } from "react";

interface Note {
  id: string;
  text: string;
  timestamp: string;
}

export function ClinicalNotes({ patientId }: { patientId: string }) {
  const [notes, setNotes] = useState<Note[]>([]);
  const [draft, setDraft] = useState("");
  const storageKey = `maternify_notes_${patientId}`;

  useEffect(() => {
    const saved = localStorage.getItem(storageKey);
    if (saved) setNotes(JSON.parse(saved));
  }, [storageKey]);

  const saveNote = () => {
    const text = draft.trim();
    if (!text) return;
    const note: Note = {
      id: Date.now().toString(),
      text,
      timestamp: new Date().toISOString(),
    };
    const next = [note, ...notes];
    setNotes(next);
    localStorage.setItem(storageKey, JSON.stringify(next));
    setDraft("");
  };

  const deleteNote = (id: string) => {
    const next = notes.filter((n) => n.id !== id);
    setNotes(next);
    localStorage.setItem(storageKey, JSON.stringify(next));
  };

  return (
    <section className="rounded-3xl bg-white p-5 shadow-sm ring-1 ring-stone-200">
      <h2 className="text-lg font-bold text-stone-900">Clinical notes</h2>
      <p className="mt-1 text-xs text-stone-400">
        Stored locally in this browser · not synced
      </p>

      <div className="mt-4 space-y-2">
        <textarea
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="Write a note... e.g. 'Called patient. Advised bed rest. Follow up in 3 days.'"
          className="w-full resize-none rounded-2xl border border-stone-300 p-4 text-sm text-stone-900 placeholder:text-stone-400 focus:outline-none focus:ring-2 focus:ring-rose-400"
          rows={3}
          onKeyDown={(e) => {
            if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) saveNote();
          }}
        />
        <div className="flex items-center justify-between">
          <p className="text-xs text-stone-400">Ctrl+Enter to save</p>
          <button
            onClick={saveNote}
            disabled={!draft.trim()}
            className="rounded-xl bg-rose-600 px-4 py-2 text-sm font-bold text-white transition-colors hover:bg-rose-700 disabled:opacity-40"
          >
            Save note
          </button>
        </div>
      </div>

      {notes.length > 0 ? (
        <div className="mt-4 space-y-3">
          {notes.map((note) => (
            <div
              key={note.id}
              className="rounded-2xl border border-stone-200 bg-stone-50 p-4"
            >
              <div className="flex items-start justify-between gap-3">
                <p className="text-sm leading-6 text-stone-800">{note.text}</p>
                <button
                  onClick={() => deleteNote(note.id)}
                  className="shrink-0 text-base text-stone-300 transition-colors hover:text-red-500"
                  aria-label="Delete note"
                >
                  ×
                </button>
              </div>
              <p className="mt-2 text-xs text-stone-400">
                {new Date(note.timestamp).toLocaleString("en-US", {
                  month: "short",
                  day: "numeric",
                  hour: "2-digit",
                  minute: "2-digit",
                })}
              </p>
            </div>
          ))}
        </div>
      ) : (
        <p className="mt-4 py-4 text-center text-sm text-stone-400">
          No notes yet for this patient.
        </p>
      )}
    </section>
  );
}
