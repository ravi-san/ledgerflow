import { create } from "zustand";
import { persist } from "zustand/middleware";

export const useLedgerStore = create(persist((set) => ({
  token: null,
  user: null,
  teams: [],
  activeTeamId: null,
  expenses: [],
  imports: [],
  memberships: [],
  setSession: ({ token, user }) => set({ token, user }),
  clearSession: () => set({ token: null, user: null, teams: [], activeTeamId: null, expenses: [], imports: [], memberships: [] }),
  setTeams: (teams) => set((state) => ({ teams, activeTeamId: teams.some((team) => team.id === state.activeTeamId) ? state.activeTeamId : teams[0]?.id || null })),
  setActiveTeamId: (activeTeamId) => set({ activeTeamId, expenses: [], imports: [], memberships: [] }),
  setExpenses: (expenses) => set({ expenses }),
  setImports: (imports) => set({ imports }),
  setMemberships: (memberships) => set({ memberships }),
}), { name: "ledgerflow-session", partialize: ({ token, user, activeTeamId }) => ({ token, user, activeTeamId }) }));
