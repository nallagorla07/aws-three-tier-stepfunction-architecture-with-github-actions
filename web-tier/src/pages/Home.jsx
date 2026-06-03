import React, { useEffect, useState } from "react";
import { fetchItems, createItem, deleteItem } from "../api/items";

export default function Home() {
  const [items, setItems]   = useState([]);
  const [name,  setName]    = useState("");
  const [desc,  setDesc]    = useState("");

  const load = () => fetchItems().then(setItems);
  useEffect(() => { load(); }, []);

  const handleAdd = async () => {
    if (!name.trim()) return;
    await createItem({ name, description: desc });
    setName(""); setDesc("");
    load();
  };

  const handleDelete = async (id) => {
    await deleteItem(id);
    load();
  };

  return (
    <main className="container">
      <h1>Items</h1>
      <div className="form">
        <input placeholder="Name"        value={name} onChange={e => setName(e.target.value)} />
        <input placeholder="Description" value={desc} onChange={e => setDesc(e.target.value)} />
        <button onClick={handleAdd}>Add</button>
      </div>
      <ul>
        {items.map(it => (
          <li key={it.id}>
            <strong>{it.name}</strong> — {it.description}
            <button onClick={() => handleDelete(it.id)}>✕</button>
          </li>
        ))}
      </ul>
    </main>
  );
}
