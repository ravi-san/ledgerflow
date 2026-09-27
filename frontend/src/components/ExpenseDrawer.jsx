import { useMemo, useState } from "react";
import { ArrowLeftRight, Check, Clock3, Pencil, RefreshCw, Send, Trash2, WalletCards, X } from "lucide-react";
import { currency, dateTime, shortDate, titleize } from "../utils/format";
import { Status } from "./Ui";

export function ExpenseDrawer({ expense, audits, role, onClose, onUpdate, onDelete, onWorkflow, onCompare }) {
  const [editing, setEditing] = useState(false);
  const [fromAudit, setFromAudit] = useState(audits[0]?.id || "");
  const [toAudit, setToAudit] = useState(audits.at(-1)?.id || "");
  const [comparison, setComparison] = useState(null);
  const [busy, setBusy] = useState(false);
  const canEdit = ["creator", "admin"].includes(role);
  const actions = useMemo(() => {
    const rows = [];
    if (["draft", "pending_review"].includes(expense.status) && canEdit) rows.push(["submit", "Submit", Send]);
    if (expense.status === "submitted" && ["approver", "admin"].includes(role)) rows.push(["approve", "Approve step", Check], ["reject", "Reject", X]);
    if (expense.status === "approved" && ["approver", "admin"].includes(role) && !expense.reimbursement) rows.push(["reimburse", "Request reimbursement", WalletCards]);
    if (expense.reimbursement?.status === "requested" && ["approver", "admin"].includes(role)) rows.push(["process_reimbursement", "Start processing", RefreshCw]);
    if (expense.reimbursement?.status === "processing" && role === "admin") rows.push(["pay_reimbursement", "Mark paid", Check]);
    return rows;
  }, [expense, role, canEdit]);

  async function workflow(action) {
    let reason = null;
    if (action === "reject") { reason = window.prompt("Enter a rejection reason"); if (!reason) return; }
    setBusy(true); try { await onWorkflow(action, reason); } finally { setBusy(false); }
  }

  async function update(event) {
    event.preventDefault(); const data = new FormData(event.currentTarget); setBusy(true);
    try { await onUpdate({ description: data.get("description"), amount_cents: Math.round(Number(data.get("amount")) * 100), spent_on: data.get("spent_on"), category: data.get("category"), lock_version: expense.lock_version }); setEditing(false); } finally { setBusy(false); }
  }

  async function compare() { if (!fromAudit || !toAudit) return; setBusy(true); try { setComparison(await onCompare(fromAudit, toAudit)); } finally { setBusy(false); } }

  return <div className="fixed inset-0 z-30 flex justify-end bg-[#10201888]" onMouseDown={onClose}><aside className="h-full w-full max-w-xl overflow-y-auto bg-white p-5 shadow-drawer sm:p-7" onMouseDown={(event) => event.stopPropagation()}>
    <header className="flex items-start justify-between gap-4 border-b pb-5"><div><p className="eyebrow mb-1">Expense #{expense.id}</p><h2 className="text-xl font-bold">{expense.description}</h2></div><button className="icon-btn" onClick={onClose} title="Close"><X size={18} /></button></header>
    <div className="flex items-center justify-between py-6"><div><small className="eyebrow block">Amount</small><strong className="text-3xl">{currency(expense.amount_cents)}</strong></div><Status value={expense.status} /></div>
    <dl className="grid grid-cols-2 gap-4 bg-[#f4f7f4] p-4 text-sm"><div><dt className="eyebrow">Spent on</dt><dd className="mt-1 font-semibold">{shortDate(expense.spent_on)}</dd></div><div><dt className="eyebrow">Category</dt><dd className="mt-1 font-semibold">{titleize(expense.category)}</dd></div><div><dt className="eyebrow">Version</dt><dd className="mt-1 font-semibold">{expense.lock_version}</dd></div><div><dt className="eyebrow">Reimbursement</dt><dd className="mt-1"><Status value={expense.reimbursement?.status || "not_requested"} /></dd></div></dl>
    {actions.length > 0 && <div className="my-5 flex flex-wrap gap-2">{actions.map(([action, label, Icon]) => <button className={action === "reject" ? "btn-danger" : "btn-primary"} disabled={busy} key={action} onClick={() => workflow(action)}><Icon size={16} />{label}</button>)}</div>}
    <div className="my-5 flex gap-3">{canEdit && !["reimbursed", "rejected"].includes(expense.status) && <button className="btn-secondary" onClick={() => setEditing(!editing)}><Pencil size={16} />Edit</button>}{role === "admin" && <button className="btn-secondary text-danger" onClick={() => window.confirm("Delete this expense? Its audit history will be retained.") && onDelete()}><Trash2 size={16} />Delete</button>}</div>
    {editing && <form className="mb-6 grid gap-3 border p-4 sm:grid-cols-2" onSubmit={update}><label className="field sm:col-span-2">Description<input className="input" name="description" defaultValue={expense.description} required /></label><label className="field">Amount<input className="input" name="amount" type="number" min="0.01" step="0.01" defaultValue={(expense.amount_cents / 100).toFixed(2)} required /></label><label className="field">Date<input className="input" name="spent_on" type="date" defaultValue={expense.spent_on} required /></label><label className="field sm:col-span-2">Category<input className="input" name="category" defaultValue={expense.category} required /></label><button className="btn-primary sm:col-span-2" disabled={busy}>Save new version</button></form>}
    {expense.approval_steps?.length > 0 && <section className="border-t py-5"><h3 className="mb-4 text-sm font-bold">Approval workflow</h3><div className="grid gap-3">{expense.approval_steps.sort((a, b) => a.stage.localeCompare(b.stage)).map((step) => <div className="flex gap-3" key={step.id}><span className={`grid size-7 shrink-0 place-items-center rounded-full ${step.decision === "approved" ? "bg-forest text-white" : step.decision === "rejected" ? "bg-danger text-white" : "bg-slate-100"}`}>{step.decision === "approved" ? <Check size={14} /> : <Clock3 size={14} />}</span><div><strong className="block text-sm">{titleize(step.stage)}</strong><small className="text-xs text-slate-500">{titleize(step.decision)}{step.decided_by ? ` by ${step.decided_by.email}` : ""}{step.decided_at ? ` · ${dateTime(step.decided_at)}` : ""}</small>{step.rejection_reason && <p className="mt-1 text-xs text-danger">{step.rejection_reason}</p>}</div></div>)}</div></section>}
    <section className="border-t py-5"><div className="mb-4 flex items-center justify-between"><h3 className="text-sm font-bold">Audit trail</h3><ArrowLeftRight size={17} className="text-moss" /></div>{audits.length > 1 && <div className="mb-4 grid grid-cols-[1fr_1fr_auto] gap-2"><select className="input" value={fromAudit} onChange={(event) => setFromAudit(event.target.value)}>{audits.map((audit) => <option value={audit.id} key={audit.id}>#{audit.id} {titleize(audit.action)}</option>)}</select><select className="input" value={toAudit} onChange={(event) => setToAudit(event.target.value)}>{audits.map((audit) => <option value={audit.id} key={audit.id}>#{audit.id} {titleize(audit.action)}</option>)}</select><button className="icon-btn" onClick={compare} disabled={busy} title="Compare versions"><ArrowLeftRight size={16} /></button></div>}
      {comparison && <div className="mb-5 border-l-4 border-gold bg-amber-50 p-3"><strong className="text-xs">{comparison.changed_fields.length} changed fields</strong>{Object.entries(comparison.changes).map(([field, values]) => <div className="mt-2 grid grid-cols-3 gap-2 text-[11px]" key={field}><span className="font-bold">{titleize(field)}</span><del className="break-all text-danger">{String(values.old ?? "empty")}</del><ins className="break-all text-forest no-underline">{String(values.new ?? "empty")}</ins></div>)}</div>}
      <div className="ml-1 border-l">{audits.map((audit) => <div className="relative pb-5 pl-5" key={audit.id}><span className="absolute -left-[5px] top-1 size-2.5 rounded-full border-2 border-white bg-moss"></span><strong className="block text-sm">{titleize(audit.action)}</strong><small className="block text-[10px] text-slate-500">{audit.user?.email} · {dateTime(audit.occurred_at)}</small><p className="mt-1 text-xs text-slate-600">{Object.keys(audit.changeset).map(titleize).join(", ")}</p></div>)}</div>
    </section>
  </aside></div>;
}
