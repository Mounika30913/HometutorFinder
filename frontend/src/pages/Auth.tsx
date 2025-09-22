import { useState } from "react";
import api from "../lib/api";
import { useAuth } from "../hooks/useAuth";

export default function Auth() {
	const [mode, setMode] = useState<"login"|"register">("login");
	const [form, setForm] = useState<any>({ email: "", password: "", name: "", role: "STUDENT" });
	const { login } = useAuth();

	async function submit(e: React.FormEvent) {
		e.preventDefault();
		try {
			const url = mode === "login" ? "/auth/login" : "/auth/register";
			const { data } = await api.post(url, form);
			login(data);
		} catch (e: any) {
			alert(e?.response?.data?.error || "Error");
		}
	}

	return (
		<div className="max-w-md mx-auto card space-y-4">
			<div className="flex gap-4">
				<button className={`btn ${mode==="login"?"bg-blue-600":"bg-gray-600"}`} onClick={() => setMode("login")}>Login</button>
				<button className={`btn ${mode==="register"?"bg-blue-600":"bg-gray-600"}`} onClick={() => setMode("register")}>Register</button>
			</div>
			<form onSubmit={submit} className="space-y-3">
				{mode==="register" && (
					<>
						<input className="input" placeholder="Name" value={form.name} onChange={e=>setForm({...form, name: e.target.value})}/>
						<select className="input" value={form.role} onChange={e=>setForm({...form, role: e.target.value})}>
							<option value="STUDENT">Student</option>
							<option value="TUTOR">Tutor</option>
						</select>
					</>
				)}
				<input className="input" placeholder="Email" value={form.email} onChange={e=>setForm({...form, email: e.target.value})}/>
				<input className="input" placeholder="Password" type="password" value={form.password} onChange={e=>setForm({...form, password: e.target.value})}/>
				<button className="btn w-full" type="submit">{mode==="login"?"Login":"Create account"}</button>
			</form>
		</div>
	);
}
