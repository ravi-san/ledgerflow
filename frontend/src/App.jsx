import { useCallback, useEffect, useMemo, useState } from "react";
import { Banknote, RefreshCw, Settings, ShieldCheck, Upload, Users, WalletCards } from "lucide-react";
import { api } from "./services/api";
import { useLedgerStore } from "./store";
import { useTeamCable } from "./hooks/useTeamCable";
import { currency } from "./utils/format";
import { AuthScreen } from "./components/AuthScreen";
import { Sidebar } from "./components/Sidebar";
import { ExpensesPanel } from "./components/ExpensesPanel";
import { ExpenseDrawer } from "./components/ExpenseDrawer";
import { ImportsPanel } from "./components/ImportsPanel";
import { MembersPanel } from "./components/MembersPanel";
import { TeamSettings } from "./components/TeamSettings";
import { Empty, Toast } from "./components/Ui";

export default function App() {
  const store = useLedgerStore();
  const [tab, setTab] = useState("expenses");
  const [selectedExpense, setSelectedExpense] = useState(null);
  const [audits, setAudits] = useState([]);
  const [toast, setToast] = useState(null);
  const [loading, setLoading] = useState(false);
  api.setToken(store.token);

  const team = useMemo(() => store.teams.find((item) => item.id === store.activeTeamId) || null, [store.teams, store.activeTeamId]);
  const notify = useCallback((message, type = "success") => { setToast({ message, type }); window.setTimeout(() => setToast(null), 4500); }, []);
  const fail = useCallback((error) => {
    if (error.status === 401) { store.clearSession(); return; }
    notify(error.message || "Something went wrong", "error");
  }, [notify, store.clearSession]);

  const loadTeams = useCallback(async () => {
    try { store.setTeams(await api.listTeams()); } catch (error) { fail(error); }
  }, [store.setTeams, fail]);

  const loadTeamData = useCallback(async () => {
    if (!store.activeTeamId) return;
    try {
      const [expenses, imports] = await Promise.all([api.listExpenses(store.activeTeamId), api.listImports(store.activeTeamId)]);
      store.setExpenses(expenses); store.setImports(imports);
      const current = store.teams.find((item) => item.id === store.activeTeamId);
      if (current?.current_role === "admin") store.setMemberships(await api.listMemberships(store.activeTeamId));
    } catch (error) { fail(error); }
  }, [store.activeTeamId, store.teams, store.setExpenses, store.setImports, store.setMemberships, fail]);

  const openExpense = useCallback(async (id) => {
    try { const [expense, history] = await Promise.all([api.getExpense(id), api.getAuditTrail(id)]); setSelectedExpense(expense); setAudits(history); } catch (error) { fail(error); }
  }, [fail]);

  const refreshSelected = useCallback(async () => {
    await loadTeamData();
    if (selectedExpense?.id) await openExpense(selectedExpense.id);
  }, [loadTeamData, openExpense, selectedExpense?.id]);

  useEffect(() => { if (store.token) loadTeams(); }, [store.token, loadTeams]);
  useEffect(() => { setSelectedExpense(null); setTab("expenses"); loadTeamData(); }, [store.activeTeamId]);
  useTeamCable(store.token, store.activeTeamId, useCallback((message) => {
    loadTeamData();
    if (selectedExpense?.id === message.expense_id) openExpense(message.expense_id);
  }, [loadTeamData, openExpense, selectedExpense?.id]));

  async function action(work, success, refresh = loadTeamData) {
    setLoading(true);
    try { const value = await work(); if (success) notify(success); if (refresh) await refresh(); return value; }
    catch (error) { fail(error); throw error; }
    finally { setLoading(false); }
  }

  async function login(email, password) {
    const session = await api.login(email, password); api.setToken(session.token); store.setSession(session);
  }

  async function createTeam(name) { await action(() => api.createTeam(name), "Team created.", loadTeams); }
  async function joinTeam(id, code) { await action(() => api.joinTeam(id, code), "Joined team as Viewer.", loadTeams); }
  async function createExpense(values) { await action(() => api.createExpense(team.id, values), "Expense created."); }

  async function updateExpense(values) {
    try { await action(() => api.updateExpense(selectedExpense.id, values), "Expense updated.", refreshSelected); }
    catch (error) { if (error.status === 409) { notify("Another user changed this expense. The latest version was loaded.", "error"); await refreshSelected(); } }
  }

  async function deleteExpense() { await action(() => api.deleteExpense(selectedExpense.id), "Expense deleted.", loadTeamData); setSelectedExpense(null); }
  async function workflow(name, reason) {
    const calls = {
      submit: () => api.submitExpense(selectedExpense.id), approve: () => api.approveExpense(selectedExpense.id), reject: () => api.rejectExpense(selectedExpense.id, reason),
      reimburse: () => api.requestReimbursement(selectedExpense.id), process_reimbursement: () => api.processReimbursement(selectedExpense.id), pay_reimbursement: () => api.payReimbursement(selectedExpense.id),
    };
    await action(calls[name], `${name.replaceAll("_", " ")} completed.`, refreshSelected);
  }

  async function queueImport(rows) {
    await action(() => api.queueImport(team.id, rows), `${rows.length} transactions queued.`, null);
    window.setTimeout(loadTeamData, 1200);
  }
  async function acceptImport(id) { await api.getImport(id); await action(() => api.acceptImport(id), "Transaction accepted."); }
  async function rejectImport(id, reason) { await api.getImport(id); await action(() => api.rejectImport(id, reason), "Transaction rejected."); }
  async function bulkAccept(ids) { await action(() => api.bulkAcceptImports(ids), `${ids.length} transactions accepted.`); }
  async function bulkReject(ids, reason) { await action(() => api.bulkRejectImports(ids, reason), `${ids.length} transactions rejected.`); }
  async function roleChange(id, role) { await action(() => api.updateMembership(team.id, id, role), "Member role updated."); }
  async function removeMember(id) { await action(() => api.deleteMembership(team.id, id), "Member removed."); }
  async function renameTeam(name) { await action(() => api.updateTeam(team.id, name), "Team name updated.", loadTeams); }

  if (!store.token) return <AuthScreen onLogin={login} />;

  const pending = store.expenses.filter((expense) => expense.status === "submitted").length;
  const approved = store.expenses.filter((expense) => ["approved", "reimbursed"].includes(expense.status)).length;
  const importQueue = store.imports.filter((item) => item.status === "pending_review").length;

  return <div className="min-h-screen lg:grid lg:grid-cols-[256px_minmax(0,1fr)]">
    <Sidebar user={store.user} teams={store.teams} activeTeamId={store.activeTeamId} onSelectTeam={store.setActiveTeamId} onCreateTeam={createTeam} onJoinTeam={joinTeam} onLogout={store.clearSession} />
    <main className="min-w-0">
      <header className="flex h-20 items-center justify-between border-b bg-white px-5 sm:px-8"><div><p className="eyebrow mb-1">Team ledger</p><h1 className="text-xl font-bold">{team?.name || "No team selected"}</h1></div><button className="icon-btn" onClick={loadTeamData} disabled={!team || loading} title="Refresh"><RefreshCw className={loading ? "animate-spin" : ""} size={17} /></button></header>
      {!team ? <Empty icon={Users} title="Create or join a team" text="Use the controls in the sidebar to open your first shared ledger." /> : <>
        <section className="grid grid-cols-2 border-b bg-white xl:grid-cols-4">{[
          [Banknote, "Total tracked", currency(store.expenses.reduce((sum, item) => sum + item.amount_cents, 0))],
          [ShieldCheck, "Awaiting approval", pending], [WalletCards, "Approved / paid", approved], [Upload, "Imports to review", importQueue],
        ].map(([Icon, label, value]) => <div className="flex min-h-24 items-center gap-3 border-b border-r p-4 xl:border-b-0 sm:p-6" key={label}><Icon className="text-moss" size={19} /><div><small className="block text-xs text-slate-500">{label}</small><strong className="mt-1 block text-xl">{value}</strong></div></div>)}</section>
        <nav className="flex gap-6 overflow-x-auto border-b bg-white px-5 sm:px-8">{[
          ["expenses", Banknote, "Expenses"], ["imports", Upload, "Imports"], ...(team.current_role === "admin" ? [["members", Users, "Members"], ["settings", Settings, "Settings"]] : []),
        ].map(([key, Icon, label]) => <button className={`flex h-[52px] shrink-0 items-center gap-2 border-b-2 text-sm font-semibold ${tab === key ? "border-forest text-forest" : "border-transparent text-slate-500"}`} key={key} onClick={() => setTab(key)}><Icon size={16} />{label}</button>)}</nav>
        {tab === "expenses" && <ExpensesPanel team={team} expenses={store.expenses} onCreate={createExpense} onOpen={openExpense} />}
        {tab === "imports" && <ImportsPanel team={team} imports={store.imports} onQueue={queueImport} onAccept={acceptImport} onReject={rejectImport} onBulkAccept={bulkAccept} onBulkReject={bulkReject} />}
        {tab === "members" && <MembersPanel memberships={store.memberships} onRoleChange={roleChange} onDelete={removeMember} />}
        {tab === "settings" && <TeamSettings team={team} onRename={renameTeam} notify={notify} />}
      </>}
    </main>
    {selectedExpense && <ExpenseDrawer expense={selectedExpense} audits={audits} role={team.current_role} onClose={() => setSelectedExpense(null)} onUpdate={updateExpense} onDelete={deleteExpense} onWorkflow={workflow} onCompare={(from, to) => api.compareExpense(selectedExpense.id, from, to)} />}
    <Toast toast={toast} onClose={() => setToast(null)} />
  </div>;
}
