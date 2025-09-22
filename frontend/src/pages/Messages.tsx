import { useEffect, useRef, useState } from "react";
import io from "socket.io-client";
import api from "../lib/api";
import { useAuth } from "../hooks/useAuth";

const socket = io(import.meta.env.VITE_API_URL || "http://localhost:4000");

export default function Messages() {
	const { user } = useAuth();
	const [withId, setWithId] = useState<number>(0);
	const [msgs, setMsgs] = useState<any[]>([]);
	const [text, setText] = useState("");
	const endRef = useRef<HTMLDivElement>(null);

	useEffect(() => {
		if (!user) return;
		socket.emit("join", String(user.id));
	}, [user]);

	useEffect(() => {
		if (!withId) return;
		(async () => {
			const { data } = await api.get(`/messages/${withId}`);
			setMsgs(data);
		})();
	}, [withId]);

	useEffect(() => {
		socket.on("message", (m: any) => {
			if (m.senderId === withId || m.receiverId === withId) {
				setMsgs(prev => [...prev, m]);
				endRef.current?.scrollIntoView({ behavior: "smooth" });
			}
		});
		return () => { socket.off("message"); }
	}, [withId]);

	async function send() {
		if (!text || !withId) return;
		const { data } = await api.post(`/messages/${withId}`, { content: text });
		setMsgs(prev => [...prev, data]);
		setText("");
		endRef.current?.scrollIntoView({ behavior: "smooth" });
	}

	return (
		<div className="card space-y-3">
			<input className="input" placeholder="Chat with user id..." value={withId||""} onChange={e=>setWithId(Number(e.target.value))}/>
			<div className="h-64 overflow-y-auto border p-2 bg-white">
				{msgs.map(m=>(
					<div key={m.id} className={`my-1 ${m.senderId===user?.id?"text-right":""}`}>
						<span className="inline-block px-2 py-1 rounded bg-gray-200">{m.content}</span>
					</div>
				))}
				<div ref={endRef} />
			</div>
			<div className="flex gap-2">
				<input className="input" value={text} onChange={e=>setText(e.target.value)} placeholder="Type a message..." />
				<button className="btn" onClick={send}>Send</button>
			</div>
		</div>
	);
}
