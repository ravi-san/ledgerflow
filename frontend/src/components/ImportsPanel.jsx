import { useState } from "react";
import Papa from "papaparse";
import { Check, FileSpreadsheet, Upload, X } from "lucide-react";
import { currency, shortDate } from "../utils/format";
import { Empty, Modal, Status } from "./Ui";

export function ImportsPanel({ team, imports, onQueue, onAccept, onReject, onBulkAccept, onBulkReject }) {
  const [selected, setSelected] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [rows, setRows] = useState([]);
  const [parseError, setParseError] = useState("");
  const canReview = ["creator", "admin"].includes(team.current_role);
  const pendingIds = imports.filter((item) => item.status === "pending_review").map((item) => item.id);

  function loadFile(file) {
    setParseError("");
    Papa.parse(file, {
      header: true,
      skipEmptyLines: true,
      complete: ({ data, errors }) => {
        if (errors.length) return setParseError(errors[0].message);
        const parsed = data.map((row) => ({ external_id: row.external_id, amount_cents: Number(row.amount_cents), description: row.description, transacted_on: row.transacted_on }));
        if (parsed.some((row) => !row.external_id || !row.amount_cents || !row.description || !row.transacted_on)) return setParseError("CSV requires external_id, amount_cents, description, and transacted_on.");
        setRows(parsed);
      },
    });
  }

  async function queue() { await onQueue(rows); setRows([]); setUploading(false); }
  async function reject(id) { const reason = window.prompt("Reason for rejection", "Not a business expense"); if (reason) await onReject(id, reason); }
  async function bulkReject() { const reason = window.prompt("Reason for rejecting selected transactions", "Not a business expense"); if (reason) { await onBulkReject(selected, reason); setSelected([]); } }

  return <section className="p-5 sm:p-8">
    <header className="mb-5 flex items-center justify-between gap-4"><div><h2 className="text-lg font-bold">Imported transactions</h2><p className="mt-1 text-xs text-slate-500">{pendingIds.length} waiting for review</p></div>{canReview && <button className="btn-secondary" onClick={() => setUploading(true)}><Upload size={17} />Import CSV</button>}</header>
    {selected.length > 0 && <div className="mb-3 flex items-center gap-2 bg-[#e8eee9] p-2.5 text-xs"><strong className="mr-auto">{selected.length} selected</strong><button className="btn-secondary min-h-8 px-2" onClick={async () => { await onBulkAccept(selected); setSelected([]); }}><Check size={15} />Accept</button><button className="btn-secondary min-h-8 px-2 text-danger" onClick={bulkReject}><X size={15} />Reject</button></div>}
    <div className="panel overflow-x-auto"><table className="w-full min-w-[760px] border-collapse text-sm"><thead className="bg-[#f7f9f7] text-left text-[10px] uppercase text-slate-500"><tr><th className="p-3"><input type="checkbox" checked={pendingIds.length > 0 && selected.length === pendingIds.length} onChange={(event) => setSelected(event.target.checked ? pendingIds : [])} /></th><th className="p-3">External ID</th><th className="p-3">Description</th><th className="p-3">Date</th><th className="p-3">Status</th><th className="p-3 text-right">Amount</th><th className="p-3"></th></tr></thead><tbody>{imports.map((item) => <tr className="border-t" key={item.id}><td className="p-3">{canReview && item.status === "pending_review" && <input type="checkbox" checked={selected.includes(item.id)} onChange={() => setSelected((ids) => ids.includes(item.id) ? ids.filter((id) => id !== item.id) : [...ids, item.id])} />}</td><td className="p-3 font-mono text-xs">{item.external_id}</td><td className="p-3">{item.description}</td><td className="p-3 text-xs text-slate-600">{shortDate(item.transacted_on)}</td><td className="p-3"><Status value={item.status} /></td><td className="p-3 text-right font-semibold tabular-nums">{currency(item.amount_cents)}</td><td className="p-3">{canReview && item.status === "pending_review" && <div className="flex justify-end gap-1"><button className="icon-btn size-8 text-forest" title="Accept" onClick={() => onAccept(item.id)}><Check size={15} /></button><button className="icon-btn size-8 text-danger" title="Reject" onClick={() => reject(item.id)}><X size={15} /></button></div>}</td></tr>)}</tbody></table>{!imports.length && <Empty icon={FileSpreadsheet} title="No imported transactions" text="Upload a CSV bank feed to begin the review workflow." />}</div>
    {uploading && <Modal title="Import bank transactions" onClose={() => setUploading(false)}><div className="grid gap-4"><div className="border border-dashed p-6 text-center"><FileSpreadsheet className="mx-auto mb-2 text-moss" size={30} /><p className="text-sm font-semibold">Choose a CSV file</p><p className="my-2 text-xs text-slate-500">Columns: external_id, amount_cents, description, transacted_on</p><input className="text-xs" type="file" accept=".csv,text/csv" onChange={(event) => event.target.files[0] && loadFile(event.target.files[0])} /></div>{parseError && <p className="text-sm text-danger">{parseError}</p>}{rows.length > 0 && <div className="bg-[#f4f7f4] p-3 text-sm"><strong>{rows.length} valid rows ready</strong><p className="mt-1 truncate text-xs text-slate-500">{rows.map((row) => row.description).join(", ")}</p></div>}<div className="flex justify-end gap-2"><button className="btn-secondary" onClick={() => setUploading(false)}>Cancel</button><button className="btn-primary" disabled={!rows.length} onClick={queue}><Upload size={16} />Queue import</button></div></div></Modal>}
  </section>;
}
