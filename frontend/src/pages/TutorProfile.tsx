import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import api from "../lib/api";
import { useAuth } from "../hooks/useAuth";

export default function TutorProfile() {
	const { id } = useParams();
	const [tutor, setTutor] = useState<any>(null);
	const [note, setNote] = useState("");
	const { user } = useAuth();

	useEffect(() => {
		(async () => {
			const { data } = await api.get(`/tutors/${id}`);
			setTutor(data);
		})();
	}, [id]);

	async function book(slotId: number) {
		if (!user) return alert("Please login");
		try {
			await api.post("/bookings", { slotId, tutorUserId: Number(id), notes: note });
			alert("Booked!");
		} catch (e: any) {
			alert(e?.response?.data?.error || "Error");
		}
	}

	if (!tutor) return null;
	return (
		<div className="space-y-4">
			<h2 className="text-xl font-bold">{tutor.name}</h2>
			<div className="text-sm text-gray-600">{tutor.tutorProfile?.subjects} â€¢ {tutor.tutorProfile?.location}</div>
			<p>{tutor.tutorProfile?.bio}</p>
			<div className="space-y-2">
				<h3 className="font-semibold">Availability</h3>
				<input className="input" placeholder="Booking note (optional)" value={note} onChange={e=>setNote(e.target.value)} />
				<div className="grid gap-2">
					{tutor.tutorProfile?.availability?.filter((s:any)=>!s.isBooked).map((s:any)=>(
						<div key={s.id} className="card flex justify-between items-center">
							<div>{new Date(s.start).toLocaleString()} - {new Date(s.end).toLocaleString()}</div>
							<button className="btn" onClick={() => book(s.id)}>Book</button>
						</div>
					))}
				</div>
			</div>
			<div>
				<h3 className="font-semibold">Reviews</h3>
				<div className="text-sm">Rating: {tutor.tutorProfile?.rating?.toFixed(1) || 0}</div>
			</div>
		</div>
	);
}
