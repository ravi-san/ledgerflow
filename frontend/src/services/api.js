export const API_URL = import.meta.env.VITE_API_URL || "http://localhost:3001";

export class ApiError extends Error {
  constructor(message, status, body) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.body = body;
  }
}

class ApiClient {
  token = null;

  setToken(token) {
    this.token = token;
  }

  async request(path, options = {}) {
    const response = await fetch(`${API_URL}${path}`, {
      ...options,
      headers: {
        Accept: "application/json",
        ...(options.body ? { "Content-Type": "application/json" } : {}),
        ...(this.token ? { Authorization: `Bearer ${this.token}` } : {}),
        ...options.headers,
      },
    });
    const body = response.status === 204 ? null : await response.json().catch(() => ({}));
    if (!response.ok) throw new ApiError(body?.message || body?.error || `Request failed (${response.status})`, response.status, body);
    return body;
  }

  login = (email, password) => this.request("/auth/login", { method: "POST", body: JSON.stringify({ email, password }) });
  listTeams = () => this.request("/teams");
  getTeam = (id) => this.request(`/teams/${id}`);
  createTeam = (name) => this.request("/teams", { method: "POST", body: JSON.stringify({ name }) });
  updateTeam = (id, name) => this.request(`/teams/${id}`, { method: "PUT", body: JSON.stringify({ name }) });
  joinTeam = (id, joinCode) => this.request(`/teams/${id}/join`, { method: "POST", body: JSON.stringify({ join_code: joinCode }) });
  listMemberships = (teamId) => this.request(`/teams/${teamId}/memberships`);
  updateMembership = (teamId, id, role) => this.request(`/teams/${teamId}/memberships/${id}`, { method: "PATCH", body: JSON.stringify({ role }) });
  deleteMembership = (teamId, id) => this.request(`/teams/${teamId}/memberships/${id}`, { method: "DELETE" });
  listExpenses = (teamId) => this.request(`/teams/${teamId}/expenses`);
  getExpense = (id) => this.request(`/expenses/${id}`);
  createExpense = (teamId, values) => this.request(`/teams/${teamId}/expenses`, { method: "POST", body: JSON.stringify(values) });
  updateExpense = (id, values) => this.request(`/expenses/${id}`, { method: "PATCH", body: JSON.stringify(values) });
  deleteExpense = (id) => this.request(`/expenses/${id}`, { method: "DELETE" });
  getAuditTrail = async (id) => normalizeAuditTrail(await this.request(`/expenses/${id}/audit_trail`));
  compareExpense = (id, from, to) => this.request(`/expenses/${id}/compare?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`);
  workflow = (id, action, body = {}) => this.request(`/expenses/${id}/${action}`, { method: "POST", body: JSON.stringify(body) });
  submitExpense = (id) => this.workflow(id, "submit");
  approveExpense = (id) => this.workflow(id, "approve");
  rejectExpense = (id, reason) => this.workflow(id, "reject", { reason });
  requestReimbursement = (id) => this.workflow(id, "reimburse");
  processReimbursement = (id) => this.workflow(id, "process_reimbursement");
  payReimbursement = (id) => this.workflow(id, "pay_reimbursement");
  listImports = (teamId) => this.request(`/teams/${teamId}/imports`);
  getImport = (id) => this.request(`/imports/${id}`);
  queueImport = (teamId, rows) => this.request(`/teams/${teamId}/imports`, { method: "POST", body: JSON.stringify({ rows }) });
  acceptImport = (id) => this.request(`/imports/${id}/accept`, { method: "POST", body: "{}" });
  rejectImport = (id, reason) => this.request(`/imports/${id}/reject`, { method: "POST", body: JSON.stringify({ reason }) });
  bulkAcceptImports = (ids) => this.request("/imports/bulk_accept", { method: "POST", body: JSON.stringify({ ids }) });
  bulkRejectImports = (ids, reason) => this.request("/imports/bulk_reject", { method: "POST", body: JSON.stringify({ ids, reason }) });
}

function normalizeAuditTrail(document) {
  const included = new Map((document.included || []).map((resource) => [`${resource.type}:${resource.id}`, resource]));

  return (document.data || []).map((resource) => {
    const userReference = resource.relationships?.user?.data;
    const user = userReference && included.get(`${userReference.type}:${userReference.id}`);
    return { id: resource.id, ...resource.attributes, user: user ? { id: user.id, ...user.attributes } : null };
  });
}

export const api = new ApiClient();
