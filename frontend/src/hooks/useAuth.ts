import { useEffect, useState } from "react";

type User = { id: number; name: string; email: string; role: "STUDENT" | "TUTOR" };

const key = "auth";
export function useAuth() {
	const [user, setUser] = useState<User | null>(() => {
		const raw = localStorage.getItem(key);
		if (!raw) return null;
		try { return JSON.parse(raw).user as User; } catch { return null; }
	});

	useEffect(() => {
		const raw = localStorage.getItem(key);
		if (raw) setUser(JSON.parse(raw).user);
	}, []);

	function login(data: { token: string; user: User }) {
		localStorage.setItem(key, JSON.stringify(data));
		setUser(data.user);
	}

	function logout() {
		localStorage.removeItem(key);
		setUser(null);
	}

	function getToken() {
		const raw = localStorage.getItem(key);
		return raw ? (JSON.parse(raw).token as string) : null;
	}

	return { user, login, logout, getToken };
}
