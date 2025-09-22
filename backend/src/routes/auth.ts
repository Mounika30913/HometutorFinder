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
