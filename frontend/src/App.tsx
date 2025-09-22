import { Routes, Route, Link, Navigate } from "react-router-dom";
import Home from "./pages/Home";
import Auth from "./pages/Auth";
import Search from "./pages/Search";
import TutorProfile from "./pages/TutorProfile";
import Dashboard from "./pages/Dashboard";
import Messages from "./pages/Messages";
import { useAuth } from "./hooks/useAuth";

export default function App() {
	const { user, logout } = useAuth();

	return (
		<div className="min-h-screen bg-gray-50">
			<nav className="bg-white border-b">
				<div className="max-w-5xl mx-auto px-4 py-3 flex justify-between">
					<Link to="/" className="font-bold">Home Tutor Finder</Link>
					<div className="flex gap-4">
						<Link to="/search">Search</Link>
						{user ? (
							<>
								<Link to="/dashboard">Dashboard</Link>
								<Link to="/messages">Messages</Link>
								<button className="text-red-600" onClick={logout}>Logout</button>
							</>
						) : <Link to="/auth">Login</Link>}
					</div>
				</div>
			</nav>
			<main className="max-w-5xl mx-auto p-4">
				<Routes>
					<Route path="/" element={<Home />} />
					<Route path="/auth" element={<Auth />} />
					<Route path="/search" element={<Search />} />
					<Route path="/tutor/:id" element={<TutorProfile />} />
					<Route path="/dashboard" element={user ? <Dashboard /> : <Navigate to="/auth" />} />
					<Route path="/messages" element={user ? <Messages /> : <Navigate to="/auth" />} />
				</Routes>
			</main>
		</div>
	);
}
