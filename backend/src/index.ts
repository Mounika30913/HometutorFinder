import "dotenv/config";
import express from "express";
import cors from "cors";
import http from "http";
import { Server } from "socket.io";
import { router as authRouter } from "./routes/auth.js";
import { router as tutorRouter } from "./routes/tutors.js";
import { router as bookingRouter } from "./routes/bookings.js";
import { router as reviewRouter } from "./routes/reviews.js";
import { router as messageRouter } from "./routes/messages.js";

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
	cors: {
		origin: process.env.CORS_ORIGIN || "http://localhost:5173",
		methods: ["GET", "POST"]
	}
});

io.on("connection", (socket) => {
	socket.on("join", (userId: string) => {
		socket.join(`user:${userId}`);
	});
});

app.set("io", io);

app.use(cors({ origin: process.env.CORS_ORIGIN || "http://localhost:5173", credentials: true }));
app.use(express.json());

app.get("/health", (_req, res) => res.json({ ok: true }));

app.use("/auth", authRouter);
app.use("/tutors", tutorRouter);
app.use("/bookings", bookingRouter);
app.use("/reviews", reviewRouter);
app.use("/messages", messageRouter);

const port = Number(process.env.PORT || 4000);
server.listen(port, () => {
	console.log(`API running on http://localhost:${port}`);
});
