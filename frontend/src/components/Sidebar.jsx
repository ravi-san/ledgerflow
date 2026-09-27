import { useState } from "react";
import { Check, CircleDollarSign, LogOut, Plus, Users } from "lucide-react";
import { initials, titleize } from "../utils/format";

export function Sidebar({ user, teams, activeTeamId, onSelectTeam, onCreateTeam, onJoinTeam, onLogout }) {
  const [mode, setMode] = useState(null);
  const [busy, setBusy] = useState(false);

  async function submitCreate(event) {
    event.preventDefault(); setBusy(true);
    try { await onCreateTeam(new FormData(event.currentTarget).get("name")); setMode(null); } finally { setBusy(false); }
  }

  async function submitJoin(event) {
    event.preventDefault(); setBusy(true); const data = new FormData(event.currentTarget);
    try { await onJoinTeam(data.get("team_id"), data.get("join_code")); setMode(null); } finally { setBusy(false); }
  }

  return <aside className="flex min-h-screen w-full flex-col bg-[#13241c] p-4 text-white lg:sticky lg:top-0 lg:h-screen lg:w-64">
    <div className="flex items-center gap-2 px-2 py-2 text-lg font-extrabold"><CircleDollarSign className="text-gold" size={25} />LedgerFlow</div>
    <p className="mb-2 mt-8 px-2 text-[10px] font-bold uppercase text-[#82948a]">Teams</p>
    <nav className="flex gap-2 overflow-x-auto lg:grid lg:overflow-visible">
      {teams.map((team) => <button className={`flex min-w-44 items-center gap-2 rounded-md p-2 text-left transition lg:min-w-0 ${team.id === activeTeamId ? "bg-[#294034]" : "text-[#bdcbc3] hover:bg-[#20352b]"}`} key={team.id} onClick={() => onSelectTeam(team.id)}><span className="grid size-8 shrink-0 place-items-center rounded bg-gold text-[10px] font-extrabold text-ink">{initials(team.name)}</span><span className="min-w-0"><strong className="block truncate text-sm">{team.name}</strong><small className="block text-[10px] text-[#8ea097]">{titleize(team.current_role)}</small></span></button>)}
    </nav>
    <div className="mt-3 grid grid-cols-2 gap-2">
      <button className="flex items-center justify-center gap-1 rounded-md border border-dashed border-[#4b5c53] p-2 text-xs text-[#b7c4bd]" onClick={() => setMode(mode === "create" ? null : "create")}><Plus size={15} />New</button>
      <button className="flex items-center justify-center gap-1 rounded-md border border-dashed border-[#4b5c53] p-2 text-xs text-[#b7c4bd]" onClick={() => setMode(mode === "join" ? null : "join")}><Users size={15} />Join</button>
    </div>
    {mode === "create" && <form className="mt-2 flex gap-1" onSubmit={submitCreate}><input className="min-w-0 flex-1 rounded border border-[#405249] bg-[#1c3026] px-2 py-2 text-xs outline-none" name="name" placeholder="Team name" required /><button className="grid size-8 place-items-center rounded bg-gold text-ink" disabled={busy}><Check size={15} /></button></form>}
    {mode === "join" && <form className="mt-2 grid gap-2" onSubmit={submitJoin}><input className="rounded border border-[#405249] bg-[#1c3026] px-2 py-2 text-xs outline-none" name="team_id" type="number" min="1" placeholder="Team ID" required /><input className="rounded border border-[#405249] bg-[#1c3026] px-2 py-2 text-xs outline-none" name="join_code" placeholder="Join code" required /><button className="rounded bg-gold p-2 text-xs font-bold text-ink" disabled={busy}>Join team</button></form>}
    <div className="mt-auto flex items-center gap-2 border-t border-[#34473d] px-2 pt-4"><span className="grid size-8 shrink-0 place-items-center rounded bg-[#355544] text-xs font-bold">{initials(user?.email)}</span><span className="min-w-0 flex-1"><strong className="block truncate text-xs">{user?.email?.split("@")[0]}</strong><small className="block truncate text-[10px] text-[#8ea097]">{user?.email}</small></span><button className="grid size-8 place-items-center rounded border border-[#405048] text-[#adbbb4]" onClick={onLogout} title="Sign out"><LogOut size={16} /></button></div>
  </aside>;
}
