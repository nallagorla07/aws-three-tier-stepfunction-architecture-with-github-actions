const BASE = "/api/items";

export const fetchItems    = () => fetch(BASE).then(r => r.json());
export const createItem    = (data) =>
  fetch(BASE, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(data) }).then(r => r.json());
export const deleteItem    = (id) => fetch(`${BASE}/${id}`, { method: "DELETE" });
