import { useEffect, useState } from "react";
import api from "../lib/api";
import { useAuth } from "../hooks/useAuth";

export default function Dashboard() {
	const { user } = useAuth();
	const [bookings, setBookings] = useState<any[]>([]);
	const [profile, setProfile] = useState<any>({ subjects: "", location: "", hourlyRate: 0, bio: "" });
	const [slot, setSlot] = useState({ start: "", end: "" });

	useEffect(() => {
		(async () => {
			const { data } = await api.get("/bookings/me");
			setBookings(data);
			if (user?.role === "TUTOR") {
				const me = await api.get(`/tutors/${user.id}`);
				setProfile(me.data.tutorProfile || {});
			}
		})();
	}, [user?.role, user?.id]);

	async function saveProfile() {
		await api.put("/tutors/me/profile", profile);
		alert("Saved");
	}

	async function addSlot() {
		await api.post("/tutors/me/availability", slot);
		alert("Added slot");
	}

	return (
		<div className="space-y-6">
			<h2 className="text-xl font-bold">Dashboard</h2>

			{user?.role === "TUTOR" && (
				<div className="card space-y-3">
					<h3 className="font-semibold">Tutor Profile</h3>
					<input className="input" placeholder="Subjects (CSV)" value={profile.subjects||""} onChange={e=>setProfile({...profile, subjects: e.target.value})}/>
					<input className="input" placeholder="Location" value={profile.location||""} onChange={e=>setProfile({...profile, location: e.target.value})}/>
					<input className="input" placeholder="Hourly Rate" type="number" value={profile.hourlyRate||0} onChange={e=>setProfile({...profile, hourlyRate: Number(e.target.value)})}/>
					<textarea className="input" placeholder="Bio" value={profile.bio||""} onChange={e=>setProfile({...profile, bio: e.target.value})}/>
					<button className="btn" onClick={saveProfile}>Save</button>

					<div className="pt-4">
						<h4 className="font-medium">Add Availability Slot</h4>
						<input className="input" type="datetime-local" value={slot.start} onChange={e=>setSlot({...slot, start: e.target.value})}/>
						<input className="input mt-2" type="datetime-local" value={slot.end} onChange={e=>setSlot({...slot, end: e.target.value})}/>
						<button className="btn mt-2" onClick={addSlot}>Add Slot</button>
					</div>
				</div>
			)}

			<div className="card">
				<h3 className="font-semibold mb-2">My Bookings</h3>
				<div className="grid gap-2">
					{bookings.map(b=>(
						<div key={b.id} className="flex justify-between">
							<div>
								<div className="font-medium">{user?.role==="STUDENT" ? b.tutor.name : b.student.name}</div>
								<div className="text-sm text-gray-600">{new Date(b.slot.start).toLocaleString()} - {new Date(b.slot.end).toLocaleString()}</div>
							</div>
							<div className="text-sm">{b.status}</div>
						</div>
					))}
				</div>
			</div>
		</div>
	);
}
