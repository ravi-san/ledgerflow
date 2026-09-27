import { useState } from "react";
import { Banknote, ChevronRight, Plus, ReceiptText } from "lucide-react";
import { currency, shortDate, titleize } from "../utils/format";
import { Empty, Modal, Status } from "./Ui";

export function ExpensesPanel({ team, expenses, onCreate, onOpen }) {
  const [creating, setCreating] = useState(false);
  const canCreate = ["creator", "admin"].includes(team.current_role);

  async function submit(event) {
    event.preventDefault(); const data = new FormData(event.currentTarget);
    await onCreate({ amount_cents: Math.round(Number(data.get("amount")) * 100), description: data.get("description"), spent_on: data.get("spent_on"), category: data.get("category") });
    setCreating(false);
  }

  return <section className="p-5 sm:p-8">
    <header className="mb-5 flex items-center justify-between gap-4"><div><h2 className="text-lg font-bold">Expenses</h2><p className="mt-1 text-xs text-slate-500">{expenses.length} ledger entries</p></div>{canCreate && <button className="btn-primary" onClick={() => setCreating(true)}><Plus size={17} />New expense</button>}</header>
    <div className="panel overflow-x-auto"><table className="w-full min-w-[760px] border-collapse text-sm"><thead className="bg-[#f7f9f7] text-left text-[10px] uppercase text-slate-500"><tr><th className="p-3">Description</th><th className="p-3">Member</th><th className="p-3">Date</th><th className="p-3">Category</th><th className="p-3">Status</th><th className="p-3 text-right">Amount</th><th></th></tr></thead><tbody>{expenses.map((expense) => <tr className="cursor-pointer border-t hover:bg-[#f8faf8]" key={expense.id} onClick={() => onOpen(expense.id)}><td className="p-3"><strong className="block">{expense.description}</strong><small className="text-[10px] text-slate-400">Version {expense.lock_version}</small></td><td className="p-3 text-xs text-slate-600">{expense.member?.email || `User ${expense.member_id}`}</td><td className="p-3 text-xs text-slate-600">{shortDate(expense.spent_on)}</td><td className="p-3 text-xs text-slate-600">{titleize(expense.category)}</td><td className="p-3"><Status value={expense.status} /></td><td className="p-3 text-right font-semibold tabular-nums">{currency(expense.amount_cents)}</td><td className="p-3"><ChevronRight size={16} /></td></tr>)}</tbody></table>{!expenses.length && <Empty icon={ReceiptText} title="No expenses yet" text={canCreate ? "Create the first expense for this team." : "This team has not recorded any expenses."} />}</div>
    {creating && <Modal title="New expense" onClose={() => setCreating(false)}><form className="grid gap-4 sm:grid-cols-2" onSubmit={submit}><label className="field sm:col-span-2">Description<input className="input" name="description" required autoFocus /></label><label className="field">Amount<input className="input" name="amount" type="number" min="0.01" step="0.01" required /></label><label className="field">Date<input className="input" name="spent_on" type="date" defaultValue={new Date().toISOString().slice(0, 10)} required /></label><label className="field sm:col-span-2">Category<select className="input" name="category" defaultValue="travel"><option value="travel">Travel</option><option value="meals">Meals</option><option value="software">Software</option><option value="operations">Operations</option><option value="supplies">Supplies</option><option value="other">Other</option></select></label><div className="flex justify-end gap-2 sm:col-span-2"><button type="button" className="btn-secondary" onClick={() => setCreating(false)}>Cancel</button><button className="btn-primary"><Banknote size={16} />Create expense</button></div></form></Modal>}
  </section>;
}
