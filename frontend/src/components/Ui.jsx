import { AlertCircle, CheckCircle2, X } from "lucide-react";
import { titleize } from "../utils/format";

const statusClasses = {
  draft: "bg-slate-100 text-slate-700",
  submitted: "bg-amber-100 text-amber-800",
  pending_review: "bg-yellow-100 text-yellow-800",
  approved: "bg-emerald-100 text-emerald-800",
  accepted: "bg-emerald-100 text-emerald-800",
  reimbursed: "bg-sky-100 text-sky-800",
  rejected: "bg-rose-100 text-rose-800",
  requested: "bg-amber-100 text-amber-800",
  processing: "bg-sky-100 text-sky-800",
  paid: "bg-emerald-100 text-emerald-800",
};

export function Status({ value }) {
  return <span className={`inline-flex min-h-6 items-center rounded px-2 text-[11px] font-bold ${statusClasses[value] || "bg-slate-100 text-slate-700"}`}>{titleize(value)}</span>;
}

export function Toast({ toast, onClose }) {
  if (!toast) return null;
  const Icon = toast.type === "error" ? AlertCircle : CheckCircle2;
  return <div className={`fixed right-5 top-5 z-50 flex max-w-sm items-start gap-3 border-l-4 bg-white p-4 shadow-xl ${toast.type === "error" ? "border-danger" : "border-forest"}`}><Icon className={toast.type === "error" ? "text-danger" : "text-forest"} size={20} /><div className="min-w-0 flex-1"><strong className="text-sm">{toast.type === "error" ? "Action failed" : "Done"}</strong><p className="mt-1 break-words text-xs text-slate-600">{toast.message}</p></div><button onClick={onClose} title="Dismiss"><X size={16} /></button></div>;
}

export function Modal({ title, children, onClose, width = "max-w-xl" }) {
  return <div className="fixed inset-0 z-40 grid place-items-center bg-[#10201899] p-4" onMouseDown={onClose}><section className={`max-h-[90vh] w-full ${width} overflow-y-auto border bg-white p-5 shadow-2xl`} onMouseDown={(event) => event.stopPropagation()}><header className="mb-5 flex items-center justify-between gap-4"><h2 className="text-lg font-bold">{title}</h2><button className="icon-btn" onClick={onClose} title="Close"><X size={18} /></button></header>{children}</section></div>;
}

export function Empty({ icon: Icon, title, text }) {
  return <div className="grid min-h-64 place-items-center p-8 text-center"><div><Icon className="mx-auto mb-3 text-moss" size={34} /><h3 className="font-bold">{title}</h3><p className="mt-1 max-w-sm text-sm text-slate-500">{text}</p></div></div>;
}
