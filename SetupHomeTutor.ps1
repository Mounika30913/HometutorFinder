# SetupHomeTutor.ps1
$ErrorActionPreference = "Stop"
$root = "C:\Users\mouni\OneDrive\Documents\hometutorcicd_project"
mkdir $root -Force | Out-Null
Set-Location $root
mkdir backend, frontend -Force | Out-Null

# docker-compose.yml
@'
version: "3.9"
services:
  db:
    image: mysql:8.0
    container_name: hometutor-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_DATABASE=hometutor
      - MYSQL_USER=app
      - MYSQL_PASSWORD=app
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 10

  backend:
    build: ./backend
    container_name: hometutor-backend
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DATABASE_URL=mysql://app:app@db:3306/hometutor
      - JWT_SECRET=CHANGE_ME_SECRET
      - NODE_ENV=development
      - PORT=4000
      - CORS_ORIGIN=http://localhost:5173
    ports:
      - "4000:4000"
    volumes:
      - ./backend:/app
      - /app/node_modules

  frontend:
    build: ./frontend
    container_name: hometutor-frontend
    depends_on:
      - backend
    environment:
      - VITE_API_URL=http://localhost:4000
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - /app/node_modules

volumes:
  db_data:
'@ | Set-Content -Encoding UTF8 "$root\docker-compose.yml"

# .gitignore
@'
node_modules
dist
.env
.env.*
.vscode
.DS_Store
'@ | Set-Content -Encoding UTF8 "$root\.gitignore"

# ===================== Backend =====================
@'
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY tsconfig.json ./
COPY prisma ./prisma
COPY src ./src

RUN npx prisma generate

EXPOSE 4000
CMD ["npm", "run", "dev"]
'@ | Set-Content -Encoding UTF8 "$root\backend\Dockerfile"

@'
{
  "name": "hometutor-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev --name init",
    "prisma:seed": "ts-node src/seed.ts"
  },
  "dependencies": {
    "@prisma/client": "^5.19.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "zod": "^3.23.8",
    "socket.io": "^4.7.5",
    "socket.io-client": "^4.7.5"
  },
  "devDependencies": {
    "prisma": "^5.19.0",
    "ts-node": "^10.9.2",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.5.4"
  }
}
'@ | Set-Content -Encoding UTF8 "$root\backend\package.json"

@'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "Node",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
'@ | Set-Content -Encoding UTF8 "$root\backend\tsconfig.json"

@'
DATABASE_URL="mysql://app:app@localhost:3306/hometutor"
JWT_SECRET="CHANGE_ME_SECRET"
PORT=4000
CORS_ORIGIN="http://localhost:5173"
'@ | Set-Content -Encoding UTF8 "$root\backend\.env"

mkdir "$root\backend\prisma" -Force | Out-Null
@'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int       @id @default(autoincrement())
  email     String    @unique
  password  String
  name      String
  role      Role
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt

  tutorProfile  TutorProfile?
  student       StudentProfile?
  reviews       Review[]        @relation("UserReviews")
  bookingsAsStudent Booking[]   @relation("StudentBookings")
  bookingsAsTutor   Booking[]   @relation("TutorBookings")
  messagesSent  Message[]       @relation("MessagesSent")
  messagesRecv  Message[]       @relation("MessagesRecv")
}

model TutorProfile {
  id           Int           @id @default(autoincrement())
  userId       Int           @unique
  user         User          @relation(fields: [userId], references: [id])
  subjects     String
  bio          String?
  hourlyRate   Decimal       @db.Decimal(10,2)
  location     String
  rating       Float         @default(0)
  reviews      Review[]
  availability AvailabilitySlot[]
}

model StudentProfile {
  id     Int   @id @default(autoincrement())
  userId Int   @unique
  user   User  @relation(fields: [userId], references: [id])
}

model AvailabilitySlot {
  id           Int      @id @default(autoincrement())
  tutorId      Int
  tutor        TutorProfile @relation(fields: [tutorId], references: [id])
  start        DateTime
  end          DateTime
  isBooked     Boolean  @default(false)
}

model Booking {
  id         Int      @id @default(autoincrement())
  studentId  Int
  student    User     @relation("StudentBookings", fields: [studentId], references: [id])
  tutorId    Int
  tutor      User     @relation("TutorBookings", fields: [tutorId], references: [id])
  slotId     Int
  slot       AvailabilitySlot @relation(fields: [slotId], references: [id])
  status     BookingStatus @default(PENDING)
  notes      String?
  createdAt  DateTime @default(now())
}

model Review {
  id         Int     @id @default(autoincrement())
  tutorId    Int
  tutor      User    @relation("UserReviews", fields: [tutorId], references: [id])
  studentId  Int
  student    User    @relation(fields: [studentId], references: [id])
  rating     Int
  comment    String?
  createdAt  DateTime @default(now())
}

model Message {
  id        Int     @id @default(autoincrement())
  senderId  Int
  receiverId Int
  sender    User    @relation("MessagesSent", fields: [senderId], references: [id])
  receiver  User    @relation("MessagesRecv", fields: [receiverId], references: [id])
  content   String
  createdAt DateTime @default(now())
}

enum Role {
  STUDENT
  TUTOR
  ADMIN
}

enum BookingStatus {
  PENDING
  CONFIRMED
  CANCELLED
  COMPLETED
}
'@ | Set-Content -Encoding UTF8 "$root\backend\prisma\schema.prisma"

mkdir "$root\backend\src\routes" -Force | Out-Null

@'
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
'@ | Set-Content -Encoding UTF8 "$root\backend\src\index.ts"

@'
import { PrismaClient } from "@prisma/client";
export const prisma = new PrismaClient();
'@ | Set-Content -Encoding UTF8 "$root\backend\src\prisma.ts"

@'
import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";

export interface AuthUser {
	id: number;
	role: "STUDENT" | "TUTOR" | "ADMIN";
}

export function signToken(payload: AuthUser) {
	const secret = process.env.JWT_SECRET || "CHANGE_ME_SECRET";
	return jwt.sign(payload, secret, { expiresIn: "7d" });
}

export function auth(requiredRoles?: AuthUser["role"][]) {
	return (req: Request, res: Response, next: NextFunction) => {
		try {
			const header = req.headers.authorization;
			if (!header?.startsWith("Bearer ")) return res.status(401).json({ error: "Unauthorized" });
			const token = header.split(" ")[1];
			const secret = process.env.JWT_SECRET || "CHANGE_ME_SECRET";
			const decoded = jwt.verify(token, secret) as AuthUser;
			if (requiredRoles && !requiredRoles.includes(decoded.role)) {
				return res.status(403).json({ error: "Forbidden" });
			}
			(req as any).user = decoded;
			next();
		} catch {
			return res.status(401).json({ error: "Unauthorized" });
		}
	};
}
'@ | Set-Content -Encoding UTF8 "$root\backend\src\auth.ts"

@'
import { Router } from "express";
import { prisma } from "../prisma.js";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { signToken } from "../auth.js";

export const router = Router();

const registerSchema = z.object({
	email: z.string().email(),
	password: z.string().min(6),
	name: z.string().min(2),
	role: z.enum(["STUDENT", "TUTOR"])
});

router.post("/register", async (req, res) => {
	const parsed = registerSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const { email, password, name, role } = parsed.data;

	const existing = await prisma.user.findUnique({ where: { email } });
	if (existing) return res.status(409).json({ error: "Email already in use" });

	const hash = await bcrypt.hash(password, 10);
	const user = await prisma.user.create({
		data: { email, password: hash, name, role }
	});

	if (role === "TUTOR") {
		await prisma.tutorProfile.create({
			data: { userId: user.id, subjects: "", location: "", hourlyRate: 0 }
		});
	} else {
		await prisma.studentProfile.create({ data: { userId: user.id } });
	}

	const token = signToken({ id: user.id, role: user.role as any });
	res.json({ token, user: { id: user.id, name: user.name, role: user.role, email: user.email } });
});

const loginSchema = z.object({
	email: z.string().email(),
	password: z.string().min(6)
});

router.post("/login", async (req, res) => {
	const parsed = loginSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const { email, password } = parsed.data;

	const user = await prisma.user.findUnique({ where: { email } });
	if (!user) return res.status(401).json({ error: "Invalid credentials" });

	const ok = await bcrypt.compare(password, user.password);
	if (!ok) return res.status(401).json({ error: "Invalid credentials" });

	const token = signToken({ id: user.id, role: user.role as any });
	res.json({ token, user: { id: user.id, name: user.name, role: user.role, email: user.email } });
});
'@ | Set-Content -Encoding UTF8 "$root\backend\src\routes\auth.ts"

@'
import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

router.get("/", async (req, res) => {
	const { q, subject, location } = req.query as any;
	const where: any = {
		tutorProfile: { is: {} }
	};
	if (q) where.name = { contains: q, mode: "insensitive" };
	if (subject) where.tutorProfile.is = { ...where.tutorProfile.is, subjects: { contains: subject } };
	if (location) where.tutorProfile.is = { ...where.tutorProfile.is, location: { contains: location } };

	const tutors = await prisma.user.findMany({
		where: { role: "TUTOR", ...where },
		select: {
			id: true, name: true, email: true, role: true,
			tutorProfile: true
		}
	});
	res.json(tutors);
});

router.get("/:id", async (req, res) => {
	const id = Number(req.params.id);
	const tutor = await prisma.user.findUnique({
		where: { id },
		select: {
			id: true, name: true, email: true, role: true,
			tutorProfile: { include: { availability: true, reviews: true } }
		}
	});
	if (!tutor || tutor.role !== "TUTOR") return res.status(404).json({ error: "Not found" });
	res.json(tutor);
});

const updateSchema = z.object({
	subjects: z.string().optional(),
	bio: z.string().optional(),
	hourlyRate: z.number().nonnegative().optional(),
	location: z.string().optional()
});

router.put("/me/profile", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const parsed = updateSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

	const profile = await prisma.tutorProfile.update({
		where: { userId: user.id },
		data: parsed.data
	});
	res.json(profile);
});

const slotSchema = z.object({
	start: z.string(),
	end: z.string()
});

router.post("/me/availability", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const parsed = slotSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const slot = await prisma.availabilitySlot.create({
		data: {
			tutor: { connect: { userId: user.id } },
			start: new Date(parsed.data.start),
			end: new Date(parsed.data.end)
		}
	});
	res.json(slot);
});

router.delete("/me/availability/:slotId", auth(["TUTOR"]), async (req, res) => {
	const user = (req as any).user as { id: number };
	const slotId = Number(req.params.slotId);
	const slot = await prisma.availabilitySlot.findUnique({ where: { id: slotId }, include: { tutor: true } });
	if (!slot || slot.tutor.userId !== user.id) return res.status(404).json({ error: "Not found" });
	await prisma.availabilitySlot.delete({ where: { id: slotId } });
	res.json({ ok: true });
});
'@ | Set-Content -Encoding UTF8 "$root\backend\src\routes\tutors.ts"

@'
import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

const createSchema = z.object({
	slotId: z.number(),
	tutorUserId: z.number(),
	notes: z.string().optional()
});

router.post("/", auth(["STUDENT"]), async (req, res) => {
	const me = (req as any).user as { id: number };
	const parsed = createSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });

	const slot = await prisma.availabilitySlot.findUnique({ where: { id: parsed.data.slotId } });
	if (!slot || slot.isBooked) return res.status(400).json({ error: "Slot unavailable" });

	const booking = await prisma.booking.create({
		data: {
			studentId: me.id,
			tutorId: parsed.data.tutorUserId,
			slotId: parsed.data.slotId,
			notes: parsed.data.notes
		}
	});
	await prisma.availabilitySlot.update({ where: { id: slot.id }, data: { isBooked: true } });
	res.json(booking);
});

router.get("/me", auth(), async (req, res) => {
	const me = (req as any).user as { id: number, role: string };
	const where = me.role === "STUDENT" ? { studentId: me.id } : { tutorId: me.id };
	const bookings = await prisma.booking.findMany({
		where,
		include: {
			slot: true,
			student: { select: { id: true, name: true } },
			tutor: { select: { id: true, name: true } }
		},
		orderBy: { createdAt: "desc" }
	});
	res.json(bookings);
});

router.post("/:id/status", auth(), async (req, res) => {
	const me = (req as any).user as { id: number, role: string };
	const id = Number(req.params.id);
	const { status } = req.body as { status: "CONFIRMED" | "CANCELLED" | "COMPLETED" };
	const booking = await prisma.booking.findUnique({ where: { id } });
	if (!booking) return res.status(404).json({ error: "Not found" });
	if (me.id !== booking.tutorId) return res.status(403).json({ error: "Forbidden" });
	const updated = await prisma.booking.update({ where: { id }, data: { status } });
	res.json(updated);
});
'@ | Set-Content -Encoding UTF8 "$root\backend\src\routes\bookings.ts"

@'
import { Router } from "express";
import { prisma } from "../prisma.js";
import { z } from "zod";
import { auth } from "../auth.js";

export const router = Router();

const createSchema = z.object({
	tutorUserId: z.number(),
	rating: z.number().min(1).max(5),
	comment: z.string().optional()
});

router.post("/", auth(["STUDENT"]), async (req, res) => {
	const me = (req as any).user as { id: number };
	const parsed = createSchema.safeParse(req.body);
	if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
	const review = await prisma.review.create({
		data: {
			studentId: me.id,
			tutorId: parsed.data.tutorUserId,
			rating: parsed.data.rating,
			comment: parsed.data.comment
		}
	});

	const agg = await prisma.review.aggregate({
		_where: { tutorId: parsed.data.tutorUserId } as any,
		_avg: { rating: true } as any
	} as any);
	await prisma.tutorProfile.update({
		where: { userId: parsed.data.tutorUserId },
		data: { rating: agg._avg?.rating ?? 0 }
	});
	res.json(review);
});
'@ | Set-Content -Encoding UTF8 "$root\backend\src\routes\reviews.ts"

@'
import { Router } from "express";
import { prisma } from "../prisma.js";
import { auth } from "../auth.js";

export const router = Router();

router.get("/:withUserId", auth(), async (req, res) => {
	const me = (req as any).user as { id: number };
	const withUserId = Number(req.params.withUserId);
	const msgs = await prisma.message.findMany({
		where: {
			OR: [
				{ senderId: me.id, receiverId: withUserId },
				{ senderId: withUserId, receiverId: me.id }
			]
		},
		orderBy: { createdAt: "asc" }
	});
	res.json(msgs);
});

router.post("/:withUserId", auth(), async (req, res) => {
	const me = (req as any).user as { id: number };
	const withUserId = Number(req.params.withUserId);
	const { content } = req.body as { content: string };
	const msg = await prisma.message.create({
		data: { senderId: me.id, receiverId: withUserId, content }
	});
	const io = req.app.get("io");
	io.to(`user:${withUserId}`).emit("message", msg);
	res.json(msg);
});
'@ | Set-Content -Encoding UTF8 "$root\backend\src\routes\messages.ts"

@'
import { prisma } from "./prisma.js";
import bcrypt from "bcryptjs";

async function main() {
	const pwd = await bcrypt.hash("password123", 10);

	const tutorUser = await prisma.user.create({
		data: {
			email: "tutor1@example.com",
			password: pwd,
			name: "Tutor One",
			role: "TUTOR",
			tutorProfile: {
				create: {
					subjects: "Math,Physics",
					location: "Hyderabad",
					hourlyRate: 25.0,
					bio: "Experienced math and physics tutor"
				}
			}
		}
	});

	const studentUser = await prisma.user.create({
		data: {
			email: "student1@example.com",
			password: pwd,
			name: "Student One",
			role: "STUDENT",
			studentProfile: { create: {} }
		}
	});

	const tp = await prisma.tutorProfile.findUnique({ where: { userId: tutorUser.id } });

	if (tp) {
		await prisma.availabilitySlot.createMany({
			data: [
				{ tutorId: tp.id, start: new Date(Date.now()+86400000), end: new Date(Date.now()+90000000) },
				{ tutorId: tp.id, start: new Date(Date.now()+2*86400000), end: new Date(Date.now()+2*90000000) }
			]
		});
	}

	console.log("Seeded users:", { tutorUser: tutorUser.email, studentUser: studentUser.email });
}

main().finally(() => prisma.$disconnect());
'@ | Set-Content -Encoding UTF8 "$root\backend\src\seed.ts"

# ===================== Frontend =====================
@'
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY index.html ./
COPY tsconfig.json vite.config.ts ./
COPY src ./src
COPY tailwind.config.js postcss.config.js ./

EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
'@ | Set-Content -Encoding UTF8 "$root\frontend\Dockerfile"

@'
{
  "name": "hometutor-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --host"
  },
  "dependencies": {
    "axios": "^1.7.2",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.1",
    "socket.io-client": "^4.7.5"
  },
  "devDependencies": {
    "@types/react": "^18.3.5",
    "@types/react-dom": "^18.3.0",
    "@types/node": "^20.14.11",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.41",
    "tailwindcss": "^3.4.10",
    "typescript": "^5.5.4",
    "vite": "^5.4.1",
    "@vitejs/plugin-react": "^4.3.1"
  }
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\package.json"

@'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
	plugins: [react()],
	server: {
		port: 5173,
		host: true
	}
});
'@ | Set-Content -Encoding UTF8 "$root\frontend\vite.config.ts"

@'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "jsx": "react-jsx",
    "moduleResolution": "Node",
    "strict": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  },
  "include": ["src", "vite.config.ts"]
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\tsconfig.json"

@'
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: { extend: {} },
  plugins: []
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\tailwind.config.js"

@'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\postcss.config.js"

@'
<!doctype html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Home Tutor Finder</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'@ | Set-Content -Encoding UTF8 "$root\frontend\index.html"

mkdir "$root\frontend\src\pages" -Force | Out-Null
mkdir "$root\frontend\src\hooks" -Force | Out-Null
mkdir "$root\frontend\src\lib" -Force | Out-Null

@'
import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
	<React.StrictMode>
		<BrowserRouter>
			<App />
		</BrowserRouter>
	</React.StrictMode>
);
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\main.tsx"

@'
@tailwind base;
@tailwind components;
@tailwind utilities;

.btn { @apply px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700; }
.input { @apply border rounded px-3 py-2 w-full; }
.card { @apply border rounded p-4 shadow-sm bg-white; }
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\styles.css"

@'
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\App.tsx"

@'
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\hooks\useAuth.ts"

@'
import axios from "axios";
const api = axios.create({
	baseURL: import.meta.env.VITE_API_URL || "http://localhost:4000"
});
api.interceptors.request.use((config) => {
	const raw = localStorage.getItem("auth");
	if (raw) {
		const { token } = JSON.parse(raw);
		if (token) config.headers.Authorization = `Bearer ${token}`;
	}
	return config;
});
export default api;
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\lib\api.ts"

@'
export default function Home() {
	return (
		<div className="space-y-4">
			<h1 className="text-2xl font-bold">Find your ideal home tutor</h1>
			<p>Search by subject, location, and availability. Browse tutor profiles, book sessions, chat, and review.</p>
		</div>
	);
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\Home.tsx"

@'
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\Auth.tsx"

@'
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
							<div className="text-sm text-gray-600">{t.tutorProfile?.subjects} • {t.tutorProfile?.location}</div>
							<div className="text-sm">Rate: ₹{t.tutorProfile?.hourlyRate}</div>
						</div>
						<Link to={`/tutor/${t.id}`} className="btn">View</Link>
					</div>
				))}
			</div>
		</div>
	);
}
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\Search.tsx"

@'
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
			<div className="text-sm text-gray-600">{tutor.tutorProfile?.subjects} • {tutor.tutorProfile?.location}</div>
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\TutorProfile.tsx"

@'
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\Dashboard.tsx"

@'
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
'@ | Set-Content -Encoding UTF8 "$root\frontend\src\pages\Messages.tsx"

# Done writing files
"Files created at $root"