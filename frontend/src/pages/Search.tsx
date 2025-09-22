import { useEffect, useState } from "react";
import api from "../lib/api";
import { Link } from "react-router-dom";

export default function Search() {
	const [filters, setFilters] = useState({ q: "", subject: "", location: "" });
	const [results, setResults] = useState<any[]>([]);

	async function fetchTutors() {
		const { data } = await api.get("/tutors", { params: filters });
		setResults(data);
	}

	useEffect(() => { fetchTutors(); }, []);

	return (
		<div className="space-y-4">
			<div className="grid grid-cols-3 gap-2">
				<input className="input" placeholder="Search name..." value={filters.q} onChange={e=>setFilters({...filters, q: e.target.value})}/>
				<input className="input" placeholder="Subject" value={filters.subject} onChange={e=>setFilters({...filters, subject: e.target.value})}/>
				<input className="input" placeholder="Location" value={filters.location} onChange={e=>setFilters({...filters, location: e.target.value})}/>
			</div>
			<button className="btn" onClick={fetchTutors}>Search</button>
			<div className="grid gap-3">
				{results.map(t => (
					<div key={t.id} className="card flex justify-between items-center">
						<div>
							<div className="font-semibold">{t.name}</div>
							<div className="text-sm text-gray-600">{t.tutorProfile?.subjects} â€¢ {t.tutorProfile?.location}</div>
							<div className="text-sm">Rate: â‚¹{t.tutorProfile?.hourlyRate}</div>
						</div>
						<Link to={`/tutor/${t.id}`} className="btn">View</Link>
					</div>
				))}
			</div>
		</div>
	);
}
