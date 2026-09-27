import { useState } from "react";
import {
  ArrowRight,
  CircleDollarSign,
  Eye,
  EyeOff,
  FileClock,
  ShieldCheck,
} from "lucide-react";

const PASSWORD_REQUIREMENTS = /^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$/;

export function AuthScreen({ onLogin }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(event) {
    event.preventDefault();
    setError("");
    if (!PASSWORD_REQUIREMENTS.test(password)) {
      setError("Password needs 8+ characters, one uppercase letter, one number, and one special character.");
      return;
    }

    setBusy(true);
    try {
      await onLogin(email, password);
    } catch (reason) {
      setError(reason.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="grid min-h-screen lg:grid-cols-[0.9fr_1.1fr]">
      <section className="flex flex-col justify-center bg-white p-8 sm:p-14 xl:p-24">
        <div className="mb-16 flex items-center gap-2 text-xl font-extrabold">
          <CircleDollarSign className="text-gold" />
          LedgerFlow
        </div>
        <p className="eyebrow mb-4">Shared finance workspace</p>
        <h1 className="max-w-xl font-serif text-4xl leading-[1.04] sm:text-5xl xl:text-6xl">
          Every expense, decision, and change in one ledger.
        </h1>
        <form className="mt-12 grid max-w-md gap-4" onSubmit={submit}>
          <label className="field">
            Email
            <input
              className="input"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="name@example.com"
              required
              autoFocus
            />
          </label>
          <label className="field">
            Password
            <span className="relative block">
              <input
                className="input pr-11"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Password@123"
                minLength={8}
                aria-describedby="password-requirements"
                required
              />
              <button
                className="absolute inset-y-0 right-0 flex w-11 items-center justify-center text-slate-500 hover:text-ink"
                type="button"
                onClick={() => setShowPassword((visible) => !visible)}
                aria-label={showPassword ? "Hide password" : "Show password"}
                title={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
              </button>
            </span>
            <small id="password-requirements" className="text-xs text-slate-500">At least 8 characters, with an uppercase letter, number, and special character.</small>
          </label>
          {error && <p className="text-sm text-danger">{error}</p>}
          <button className="btn-primary justify-between" disabled={busy}>
            {busy ? "Signing in..." : "Sign in"}
            <ArrowRight size={17} />
          </button>
        </form>
      </section>
      <section className="hidden place-items-center overflow-hidden bg-[#193126] p-16 lg:grid">
        <div className="w-full max-w-2xl -rotate-2 border border-[#d7cfb5] bg-[#f6f0de] p-9 shadow-[24px_28px_0_#0e2118]">
          <div className="flex justify-between border-b-2 border-ink pb-5 font-mono text-xs font-bold">
            <span>TEAM LEDGER / LIVE</span>
            <ShieldCheck className="text-forest" size={19} />
          </div>
          {[
            ["Cloud hosting", "$240.00", "Approved"],
            ["Client lunch", "$86.40", "Submitted"],
            ["Rail ticket", "$119.00", "Reimbursed"],
          ].map((row) => (
            <div
              className="grid grid-cols-[1fr_auto_100px] gap-4 border-b border-[#c9c2ad] py-6"
              key={row[0]}
            >
              <strong>{row[0]}</strong>
              <span>{row[1]}</span>
              <small className="text-right text-slate-600">{row[2]}</small>
            </div>
          ))}
          <div className="ml-auto mt-10 flex w-max rotate-2 items-center gap-2 border-2 border-danger px-3 py-2 font-mono text-xs font-bold uppercase text-danger">
            <FileClock size={20} />
            Complete audit history
          </div>
        </div>
      </section>
    </main>
  );
}
