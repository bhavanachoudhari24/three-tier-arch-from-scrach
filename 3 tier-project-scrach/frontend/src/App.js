import React, { useEffect, useState } from "react";
import axios from "axios";

function App(){
  const [users, setUsers] = useState([]);
  useEffect(()=>{
    axios.get("/api/users")
      .then(r => setUsers(r.data))
      .catch(e => console.error(e));
  },[]);
  return (
    <div style={{padding:20}}>
      <h1>3-Tier Demo</h1>
      <h3>Users</h3>
      <ul>
        {users.map(u => <li key={u.id}>{u.name} — {u.email}</li>)}
      </ul>
    </div>
  );
}

export default App;
